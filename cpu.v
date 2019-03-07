module cpu(
    input wire clk,
    input wire nreset,
    output wire led,
    output wire [7:0] debug_port1,
    output wire [7:0] debug_port2,
    output wire [7:0] debug_port3
    );
    localparam code_width = 32;
    localparam code_width_l2b = $clog2(code_width / 8);
    localparam code_words = 12;
    localparam code_words_l2 = $clog2(code_words);
    localparam code_addr_width = code_words_l2;
    reg [code_width - 1:0]  code_mem[0:code_words - 1];
    wire [code_width - 1:0]  code_mem_rd;
    wire [code_addr_width - 1:0] code_addr;

	reg [31:0] rf [0:14];  // register 15 is the pc

    reg [code_width - 1:0]  pc;

    localparam r15 = 4'b1111;
    localparam r14 = 4'b1110;

    reg [31:0] cpsr;        // program status register, for cmp
    localparam cpsr_n = 31; //n=1 when negative value
    localparam cpsr_z = 30; //z=1 when two numbers are equal
    localparam cpsr_c = 29; //c=1 when unsigned higher or same
    localparam cpsr_v = 28; //v=1 when there is singed overflow

    //register file constants and values from instruction (if applicable)
    reg [3:0]  rf_rs1; //read register 1, select on mux
    reg [3:0]  rf_rs2; //read register 2, select on mux
    reg [3:0]  rf_ws;  //register select on decoder
    reg [31:0] rf_wd;  //write data onto selected register
    reg        rf_we;  //register write, enables decoder
    reg [31:0] rf_d1;  //read data 1
    reg [31:0] rf_d2;  //read data 2
    function automatic [3:0] inst_rn;
        input [31:0] inst;
        inst_rn = inst[19:16];
    endfunction

    function automatic [3:0] inst_rd;
        input [31:0] inst;
        inst_rd = inst[15:12];
    endfunction

    function automatic [3:0] inst_rs;
        input [31:0] inst;
        inst_rs = inst[11:8];
    endfunction

    function automatic [3:0] inst_rm;
        input [31:0] inst;
        inst_rm = inst[3:0];
    endfunction

    function automatic inst_rs_isreg;
        input [31:0] inst;
        if (inst[4] == 1'b1 && inst[7] == 1'b0)
            inst_rs_isreg = 1'b1;
        else
            inst_rs_isreg = 1'b0;
    endfunction

    function automatic [7:0] inst_data_proc_imm;
        input [31:0]  inst;
        inst_data_proc_imm = inst[7:0];
    endfunction

    localparam operand2_is_reg = 1'b0;
    localparam operand2_is_imm = 1'b1;
    function automatic operand2_type; //immediate offset
        input [31:0]  inst;
        operand2_type = inst[25];
    endfunction

    //condtion code constants and values from instruction (if applicable)
    localparam cond_eq = 4'b0000;
    localparam cond_ne = 4'b0001;
    localparam cond_cs = 4'b0010;
    localparam cond_cc = 4'b0011;
    localparam cond_ns = 4'b0100;
    localparam cond_nc = 4'b0101;
    localparam cond_vs = 4'b0110;
    localparam cond_vc = 4'b0111;
    localparam cond_hi = 4'b1000;
    localparam cond_ls = 4'b1001;
    localparam cond_ge = 4'b1010;
    localparam cond_lt = 4'b1011;
    localparam cond_gt = 4'b1100;
    localparam cond_le = 4'b1101;
    localparam cond_al = 4'b1110; //always
    function automatic [3:0] inst_cond;
        input [31:0]  inst;
        inst_cond = inst[31:28];
    endfunction

    function automatic inst_branch_islink;
        input [31:0]   inst;
        inst_branch_islink = inst[24];
    endfunction

    function automatic [31:0] inst_branch_imm;
        input [31:0]  inst;
        inst_branch_imm = { {6{inst[23]}}, inst[23:0], 2'b00 };
    endfunction

    localparam inst_type_branch     = 2'b10; //for branches
    localparam inst_type_data_proc  = 2'b00; //for data processing
    localparam inst_type_data_trans = 2'b01; //for load and store
    function automatic [1:0] inst_type;
        input [31:0]  inst;
        inst_type = inst[27:26];
    endfunction

    //operation code constants and values from instruction (if applicable)
    localparam opcode_and  = 4'b0000; //Op1 AND Op2
    localparam opcode_eor  = 4'b0001; //Op1 EOR Op2
    localparam opcode_sub  = 4'b0010; //Op1 - Op2
    localparam opcode_rsb  = 4'b0011; //Op2 - Op1
    localparam opcode_add  = 4'b0100; //Op1 + Op2
    localparam opcode_adc  = 4'b0101; //Op1 + Op2 + Carry
    localparam opcode_sbc  = 4'b0110; //Op1 - Op2 + Carry - 1
    localparam opcode_rsc  = 4'b0111; //Op2 - Op1 + Carry - 1
    localparam opcode_tst  = 4'b1000; //set condition codes on Op1 AND Op2
    localparam opcode_teq  = 4'b1001; //set condition codes on Op1 EOR Op2
    localparam opcode_cmp  = 4'b1010; //set condition codes on Op1 - Op2
    localparam opcode_cmpn = 4'b1011; //set condition codes on Op1 + Op2
    localparam opcode_orr  = 4'b1100; //Op1 OR Op2
    localparam opcode_mov  = 4'b1101; //Op2
    localparam opcode_bic  = 4'b1110; //Op1 AND NOT Op2
    localparam opcode_mvn  = 4'b1111; //NOT Op2
    function automatic [3:0] inst_opcode;
        input [31:0]  inst;
        inst_opcode = inst[24:21];
    endfunction

    //memory constants and values from instruction (if applicable)
    localparam data_width = 32;
    localparam data_width_l2b = $clog2(data_width / 8);
    localparam data_words = 32;
    localparam data_words_l2 = $clog2(data_words);
    localparam data_addr_width = data_words_l2;
    reg [data_width - 1:0]       data_mem[data_words - 1:0];
    reg [data_width - 1:0]       data_mem_rd;
    reg [data_width - 1:0]       data_mem_wd;
    reg [data_addr_width - 1:0]  data_addr;
    reg data_mem_we;
    function automatic inst_losto_bit; //load/store bit
        input [31:0]  inst;
        inst_losto_bit = inst[20];
    endfunction
    function automatic [11:0] inst_memoff; //memory offset
        input [31:0] inst;
        inst_memoff = inst[4:0];
    endfunction

    //pipeline variables
    //stage 1
    reg [31:0] inst_fetch, pc_fetch, inst_dec, pc_dec, inst_temp, pc_temp;
    //stage 2
    reg [31:0] inst_exec, pc_exec, rf_d1_exec, rf_d2_exec, rf_d1_dec, rf_d2_dec, alu_result_exec;
    reg [3:0] rf_ws_exec, rf_ws_dec, rf_rs1_dec, rf_rs2_dec;
    //stage 3
    reg [31:0] inst_mem, pc_mem, rf_d1_mem, alu_result_mem, rf_wd_mem;
    reg [3:0] rf_ws_mem;
    //stage 4
    reg [31:0] inst_wb, pc_wb, rf_wd_wb;
    reg [3:0] rf_ws_wb;
    reg [data_width - 1:0] data_mem_rd_mem, data_mem_rd_wb;
    //pipeline branching
	reg [31:0] branch_target, branch_target_mem, branch_target_exec;
	reg cond_go, cond_go_mem, cond_go_exec;
    //pipeline stalling
    reg stall, stall_exec, stall_mem, stall_wb;
//------execution of intructions are done after this portion--------

	//-------instruction fetch begin--------
    initial begin
        code_mem[0] = 32'b1110_00_1_1101_0_0010_0010_00000000_0111;  // MOV r2, #7
        code_mem[1] = 32'b1110_01_00000_0_0010_0010_000000000001;    // STR r2
        code_mem[2] = 32'b1110_00_1_0100_0_0010_0010_00000000_0010;  // ADD r2, r2, #2
        code_mem[3] = 32'b1110_00_1_1010_1_0010_0000_00000000_1000;  // CMP r2, #9
        code_mem[4] = 32'b0000_101_0_11111111_11111111_11111010;     // conditional branch, B.EQ -4
        code_mem[5] = 32'b1110_01_00000_1_0010_0010_000000000001;    // LDR r2
        code_mem[6] = 32'b1110_00_1_1101_0_0011_0011_00000000_1111;  // MOV r3, #15
        code_mem[7] = 32'b1110_01_00000_0_0011_0011_000000000111;    // STR r3
        code_mem[8] = 32'b1110_00_0_0010_0_0011_0011_00000000_0010;  // SUB r3, r3, r2 (r3=15-7=8)
        code_mem[9] = 32'b1110_01_00000_1_0011_0011_000000000111;    // LDR r3
        code_mem[10] = 32'b1110_00_0_0000_0_0011_0011_00000000_0010; // AND r3, r3, r2
        code_mem[11] = 32'b1110_101_1_11111111_11111111_11110011;    // branch with link PC = (PC + 8) - 52 = PC - 44

		// rf[1] = '0;
		// rf[2] = '0;
		// rf[3] = '0;
        // code_mem[0] = 32'b1110_00_1_1101_0_0010_0010_00000000_0111; // MOV r2, #7
		// code_mem[1] = 32'b1110_01_00000_0_0010_0010_000000000001;   // STR r2
        // //code_mem[2] = 32'b1110_00_1_0100_0_0001_0001_00000000_0101; // ADD r1, r1, #5
        // code_mem[2] = 32'b1110_00_1_0100_0_0010_0010_00000000_0101; // ADD r2, r2, #5
        // code_mem[3] = 32'b1110_01_00000_1_0010_0010_000000000001;   // LDR r2
		// code_mem[4] = 32'b1110_00_1_0100_0_0010_0010_00000000_0011; // ADD r2, r2, #3
		// code_mem[5] = 32'b1110_00_1_0100_0_0011_0011_00000000_0100; // ADD r3, r3, #4
        // code_mem[6] = 32'b1110_00_1_1010_1_0010_0000_00000000_1001; // CMP r2, #9
		// code_mem[7] = 32'b1110_101_1_11111111_11111111_11110111;	// PC = (PC + 8) - 52 = PC - 44
    end

	assign code_addr = pc[code_addr_width - 1 + 2:2];
    assign code_mem_rd = code_mem[code_addr];

    //  "Fetch" from code memory into instruction bits
    reg [31:0] inst;
    always @(*) begin
        inst = code_mem_rd;
    end

	 // increment PC
    always @(posedge clk) begin
        if (!nreset)
            pc <= 32'd0;
        else begin
			if ((inst_type(inst_exec) == inst_type_branch) && cond_go_exec) pc <= branch_target_exec;
			else if (stall) pc <= pc;
			else pc <= pc + 4;
        end
    end
	//-------instruction fetch end--------

	//-------pipeline stage 1 (IF/ID)--------
	always @ (*) begin
		inst_fetch = inst;
		pc_fetch = pc;

	end

	always @ (posedge clk) begin
        stall <= (!stall & inst_type(inst_dec) & inst_losto_bit(inst_dec) & ((inst_rd(inst_dec) == inst_rd(inst_fetch)) | (inst_rd(inst_dec) == inst_rn(inst_fetch))));
        if (stall) begin
    		pc_dec <= pc_dec;
    		inst_dec <= inst_dec;
        end
        else begin
            pc_dec <= pc_fetch;
    	    inst_dec <= inst_fetch;
        end
	end
	//-------pipeline stage 1 (IF/ID)--------

    //-------instruction decode begin--------
    // "Decode" what gets read and written
    always @(*) begin
        //branch with link: save PC to R14
        if ((inst_type(inst_dec) == inst_type_branch) & inst_branch_islink(inst_dec))
            rf_ws = r14;
        else
            rf_ws  = inst_rd(inst_dec);
        rf_rs1 = inst_rn(inst_dec);
        rf_rs2 = inst_rm(inst_dec);
		rf_d1 = (rf_rs1 == r15) ? pc_dec : rf[rf_rs1]; // what to read from port 1
		rf_d2 = (rf_rs2 == r15) ? pc_dec : rf[rf_rs2]; // what to read from port 2
	end
	//-------instruction decode end--------

    //-------pipeline stage 2 (ID/EX)--------
    always @ (*) begin
        rf_d1_dec = rf_d1;
        rf_d2_dec = rf_d2;
        rf_ws_dec = rf_ws;
        rf_rs1_dec = rf_rs1;
        rf_rs2_dec = rf_rs2;
    end

	always @ (posedge clk) begin
		pc_exec    <= pc_dec;
		inst_exec  <= inst_dec;
        rf_ws_exec <= rf_ws_dec;
        stall_exec <= stall;

        if (stall_exec)
            rf_d1_exec <= data_mem_rd_mem;
        else if ((rf_ws_exec == rf_rs1_dec) & (inst_type(inst_exec) == inst_type_data_proc))
            rf_d1_exec <= alu_result_exec;
        else if ((rf_ws_mem == rf_rs1_dec))
            rf_d1_exec <= rf_wd_mem;
        else if ((rf_ws_wb  == rf_rs1_dec))
            rf_d1_exec <= rf_wd_wb;
        else
            rf_d1_exec <= rf_d1_dec;

        if (stall_exec)
            rf_d2_exec <= data_mem_rd_mem;
        else if ((rf_ws_exec == rf_rs2_dec) & (inst_type(inst_exec) == inst_type_data_proc))
            rf_d2_exec <= alu_result_exec;
        else if ((rf_ws_mem == rf_rs2_dec))
            rf_d2_exec <= rf_wd_mem;
        else if ((rf_ws_wb  == rf_rs2_dec))
            rf_d2_exec <= rf_wd_wb;
        else
            rf_d2_exec <= rf_d2_dec;
	end
	//-------pipeline stage 2 (ID/EX)--------

    //-------execution begin--------
	reg [31:0] operand2;
    reg [31:0] alu_result;

    always @(*) begin
        // compute second operand
        if (operand2_type(inst_exec) == operand2_is_reg)
            operand2 = rf_d2_exec;
        else
            operand2 = {24'd0, inst_data_proc_imm(inst_exec)};

        // "Execute" the instruction
		if (inst_type(inst_exec) == inst_type_branch) begin
			case (inst_cond(inst_exec))
				cond_eq: cond_go =  cpsr[cpsr_z];
				cond_ne: cond_go = ~cpsr[cpsr_z];
				cond_cs: cond_go =  cpsr[cpsr_c];
				cond_cc: cond_go = ~cpsr[cpsr_c];
				cond_ns: cond_go =  cpsr[cpsr_n];
				cond_nc: cond_go = ~cpsr[cpsr_n];
				cond_vs: cond_go =  cpsr[cpsr_v];
				cond_vc: cond_go = ~cpsr[cpsr_v];
				cond_hi: cond_go = (cpsr[cpsr_c] & ~cpsr[cpsr_z]);
				cond_ls: cond_go = (cpsr[cpsr_c] | ~cpsr[cpsr_z]);
				cond_ge: cond_go = (cpsr[cpsr_n] == cpsr[cpsr_v]);
				cond_lt: cond_go = (cpsr[cpsr_n] != cpsr[cpsr_v]);
				cond_gt: cond_go = (~cpsr[cpsr_z] & (cpsr[cpsr_n] == cpsr[cpsr_v]));
				cond_le: cond_go = (cpsr[cpsr_z] | (cpsr[cpsr_n] != cpsr[cpsr_v]));
				cond_al: cond_go = 1'b1;
				default: cond_go = 1'b1;
			endcase
		end

        case (inst_opcode(inst_exec))
            opcode_and: alu_result = rf_d1_exec & operand2;
            opcode_eor: alu_result = rf_d1_exec ^ operand2;
            opcode_sub: alu_result = rf_d1_exec - operand2;
            opcode_rsb: alu_result = operand2 - rf_d1_exec;
            opcode_add: alu_result = rf_d1_exec + operand2;
            opcode_adc: alu_result = rf_d1_exec + operand2 + cpsr[cpsr_c];
            opcode_sbc: alu_result = rf_d1_exec - operand2 + cpsr[cpsr_c] - 32'h0000_0001;
            opcode_rsc: alu_result = operand2 - rf_d1_exec + cpsr[cpsr_c] - 32'h0000_0001;
            opcode_tst: begin
                            cpsr[cpsr_n] = (rf_d1_exec & operand2) < 0;
                            cpsr[cpsr_z] = (rf_d1_exec & operand2) == 0;
                            cpsr[cpsr_c] = (rf_d1_exec & operand2) > 32'hffffffff;
                            cpsr[cpsr_v] = (rf_d1_exec & operand2) > 32'h7fffffff;
                        end
            opcode_teq: begin
                            cpsr[cpsr_n] = (rf_d1_exec ^ operand2) < 0;
                            cpsr[cpsr_z] = (rf_d1_exec ^ operand2) == 0;
                            cpsr[cpsr_c] = (rf_d1_exec ^ operand2) > 32'hffffffff;
                            cpsr[cpsr_v] = (rf_d1_exec ^ operand2) > 32'h7fffffff;
                        end
            opcode_cmp: begin
                            cpsr[cpsr_n] = (rf_d1_exec - operand2) < 0;
                            cpsr[cpsr_z] = (rf_d1_exec - operand2) == 0;
                            cpsr[cpsr_c] = (rf_d1_exec - operand2) > 32'hffffffff;
                            cpsr[cpsr_v] = (rf_d1_exec - operand2) > 32'h7fffffff;
                        end
            opcode_cmpn:begin
                            cpsr[cpsr_n] = (rf_d1_exec + operand2) < 0;
                            cpsr[cpsr_z] = (rf_d1_exec + operand2) == 0;
                            cpsr[cpsr_c] = (rf_d1_exec - operand2) > 32'hffffffff;
                            cpsr[cpsr_v] = (rf_d1_exec - operand2) > 32'h7fffffff;
                        end
            opcode_orr: alu_result = rf_d1_exec | operand2;
            opcode_mov: alu_result = operand2;
            opcode_bic: begin
                            alu_result = rf_d1_exec & ~operand2;
                            cpsr[cpsr_n] = 1'b0;
                            cpsr[cpsr_z] = 1'b0;
                            cpsr[cpsr_c] = 1'b0;
                            cpsr[cpsr_v] = 1'b0;
                        end
            opcode_mvn: alu_result = ~operand2;
            default:    alu_result = 32'h0;
        endcase

        branch_target = pc_exec + 8 + inst_branch_imm(inst_exec);
    end
	//-------execution end--------

    //-------pipeline stage 3 (EX/MEM)--------
    always @ (*) begin
        alu_result_exec = alu_result;
		branch_target_exec = branch_target;
		cond_go_exec = cond_go;
    end

    always @ (posedge clk) begin
        inst_mem            <= inst_exec;
        pc_mem              <= pc_exec;
        rf_d1_mem           <= rf_d1_exec;
        alu_result_mem      <= alu_result_exec;
        rf_ws_mem           <= rf_ws_exec;
		cond_go_mem         <= cond_go_exec;
		branch_target_mem   <= branch_target_exec;
        stall_mem           <= stall_exec;
    end
    //-------pipeline stage 3 (EX/MEM)--------

    //-------memory begin--------
    always @(*) begin
        // "Decode" whether we write to memory
        if (inst_type(inst_mem) == inst_type_data_trans) data_mem_we = !(inst_losto_bit(inst_mem));
        else                                             data_mem_we = 1'b0;

		if (inst_type(inst_mem) == inst_type_data_trans)
            data_addr = rf_d1_mem[4:0] + inst_memoff(inst_mem);

        if ((inst_type(inst_mem) == inst_type_branch) & inst_branch_islink(inst_mem))
            rf_wd = pc_mem;
        else if ((inst_type(inst_mem) == inst_type_data_trans) & inst_losto_bit(inst_mem))
            rf_wd = data_mem_rd;
        else
            rf_wd = alu_result_mem;
	end

    //load/store to memory
    always @(posedge clk) begin
        if (data_mem_we)
            data_mem[data_addr] <= rf_d1_mem;
        data_mem_rd <= data_mem[data_addr];
    end
	//-------memory end--------

    //-------pipeline stage 4 (MEM/WB--------
    always @ (*) begin
        data_mem_rd_mem = data_mem_rd;
        rf_wd_mem = rf_wd;
    end

    always @ (posedge clk) begin
        inst_wb         <= inst_mem;
        pc_wb           <= pc_mem;
        rf_ws_wb        <= rf_ws_mem;
        data_mem_rd_wb  <= data_mem_rd_mem;
        rf_wd_wb        <= rf_wd_mem;
        stall_wb        <= stall_mem;
    end
    //-------pipeline stage 4 (MEM/WB)--------

	//-------write back begin--------
    // "Write back" the instruction
    always @(*) begin
    // "Decode" whether we write the register file
        if (stall_wb) rf_we = 1'b0;
        else begin
            case (inst_type(inst_wb))
                inst_type_branch:     rf_we = inst_branch_islink(inst_wb);
                inst_type_data_proc:  if (inst_cond(inst_wb) == cond_al) rf_we = 1'b1;
                inst_type_data_trans: rf_we = inst_losto_bit(inst_wb);
                default:              rf_we = 1'b0;
            endcase
        end

        if (nreset && rf_we)
            if (rf_ws_wb != r15)
                rf[rf_ws_wb] = rf_wd_wb;
    end
	//-------write back end--------

    //outputs
	assign led = pc[2];
    assign debug_port1 = pc[9:2];
    assign debug_port2 = rf[4];
    assign debug_port3 = code_mem_rd[7:0];
endmodule

module cpu_testbench();
   reg clk, nreset;
   wire led;
   wire [7:0] debug_port1, debug_port2, debug_port3;

   cpu dut (.clk(clk), .nreset(nreset), .led(led), .debug_port1(debug_port1), .debug_port2(debug_port2), .debug_port3(debug_port3));

   parameter CLOCK_PERIOD=100;
   initial begin
	   clk <= 0;
	   forever #(CLOCK_PERIOD/2) clk <= ~clk;
   end

   initial begin
	   nreset <= 0; repeat (1) @(posedge clk);
	   nreset <= 1; repeat(40) @(posedge clk);
	   $stop;
   end
endmodule
