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
    localparam code_words = 8;
    localparam code_words_l2 = $clog2(code_words);
    localparam code_addr_width = code_words_l2;
    reg [code_width - 1:0]  code_mem[0:code_words - 1];
    wire [code_width - 1:0]  code_mem_rd;
    wire [code_addr_width - 1:0] code_addr;

    //instructions
    //only 8-instructions for asynch
    initial begin
        rf[2] = 32'b00000000000000000000000000000111; //7
        rf[3] = 32'b00000000000000000000000000001111; //15
        data_mem[10010] = 32'b00000000000000000000000000010111; //17 //1f
        code_mem[0] = 32'b1110_000_0100_0_0010_0010_00000000_0001;  // ADD r2, r2, r1
        //code_mem[1] = 32'b1110_101_0_11111111_11111111_11111101;   // branch -12 which is PC = (PC + 8) - 12 = PC - 4
        //code_mem[1] = 32'b1110_101_1_11111111_11111111_11111101; //branch with link (write current PC into R14)
        code_mem[1] = 32'b1110_01_00000_0_0010_0010_000000000001; //store
        code_mem[2] = 32'b1110_01_00000_1_0010_0010_000000000001; //load
        code_mem[3] = 32'b1110_101_0_11111111_11111111_11111011;   // branch -20 which is PC = (PC + 8) - 20 = PC - 12
    end

    //program counter variables
    reg [code_width - 1:0]  pc;
    assign code_addr = pc[code_addr_width - 1 + 2:2];
    assign code_mem_rd = code_mem[code_addr];

    assign led = pc[2]; // make the LED blink on the low order bit of the PC

    //debug port outputs
    assign debug_port1 = pc[9:2];
    assign debug_port2 = code_mem_rd[7:0];
    assign debug_port3 = data_mem_rd[7:0];

    reg [31:0] rf[0:14];  // register 15 is the pc
    initial begin
        rf[1] <= 32'd1;     // for testing
    end
    localparam r15 = 4'b1111;
    localparam r14 = 4'b1110;

    //https://azeria-labs.com/arm-conditional-execution-and-branching-part-6/
    reg [31:0] cpsr;    // program status register, for cmp
    localparam cpsr_n = 31; //n=v when a SIGNED number is greater than or equal to another
                            //n=1 when negative value and n=0 when positive value
    localparam cpsr_z = 30; //z=1 when two numbers are equal
    localparam cpsr_c = 29; //c=1 when unsigned higher or same
    localparam cpsr_v = 28; //v=1 when there is singed overflow

    //register file constants and values from instruction (if applicable)
    reg [3:0]   rf_rs1; //read register 1, select on mux
    reg [3:0]   rf_rs2; //read register 2, select on mux
    reg [3:0]   rf_ws;  //register select on decoder
    reg [31:0]  rf_wd;  //write data onto selected register
    reg         rf_we;  //register write, enables decoder
    wire [31:0] rf_d1;  //read data 1
    wire [31:0] rf_d2;  //read data 2
    assign rf_d1 = (rf_rs1 == r15) ? pc : rf[rf_rs1]; // what to read from port 1
    assign rf_d2 = (rf_rs2 == r15) ? pc : rf[rf_rs2]; // what to read from port 2
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
    function automatic inst_index_bit; //pre/post indexing bit: dont worry
        input [31:0]  inst;
        inst_index_bit = inst[24];
    endfunction
    function automatic inst_updown_bit; //up/down bit: dont worry
        input [31:0]  inst;
        inst_updown_bit = inst[23];
    endfunction
    function automatic inst_word_bit;  //byte/word bit: dont worry
        input [31:0]  inst;
        inst_word_bit = inst[22];
    endfunction
    function automatic inst_wback_bit; //write-back bit: dont worry
        input [31:0]  inst;
        inst_wback_bit = inst[21];
    endfunction
    function automatic inst_losto_bit; //load/store bit
        input [31:0]  inst;
        inst_losto_bit = inst[23];
    endfunction
    function automatic [11:0] inst_memoff; //memory offset
        input [31:0] inst;
        inst_memoff = inst[4:0];
    endfunction

//------execution of intructions are done after this portion--------

    //  "Fetch" from code memory into instruction bits
    reg [31:0] inst;
    always @(*) begin
        inst = code_mem_rd;
    end

    // "Decode" the second operand
    reg [31:0] operand2;
    // compute second operand
    always @(*) begin
        // For now, we only support R type unshifted instructions.
        // shifts and such are NOT implemented.
        if (operand2_type(inst) == operand2_is_reg) operand2 = rf_d2;
        else operand2 = inst_data_proc_imm(inst);
    end

    // "Decode" what gets read and written
    always @(*) begin
        //branch with link: save PC to R14
        if (inst_branch_islink(inst))  rf_ws = r14;
        else                           rf_ws  = inst_rd(inst);
        rf_rs1 = inst_rn(inst);
        rf_rs2 = inst_rm(inst);
    end

    // "Decode" whether we write the register file
    always @(*) begin
        rf_we = 1'b0;
        case (inst_type(inst))
            //if branch is link, write enable
            inst_type_branch: if (inst_branch_islink(inst)) rf_we = 1'b1; else rf_we = 1'b0;
            inst_type_data_proc: if (inst_cond(inst) == cond_al) rf_we = 1'b1;
            inst_type_data_trans: if (inst_losto_bit
                (inst)) rf_we = 1'b1;
                                  else rf_we = 1'b0;
        endcase
    end

    // "Decode" whether we write to memory
    always @(*) begin
        data_mem_we = 1'b0;
        case (inst_type(inst))
            inst_type_branch:     data_mem_we = 1'b0;
            inst_type_data_proc:  data_mem_we = 1'b0;
            inst_type_data_trans: if (!inst_losto_bit
                (inst)) data_mem_we = 1'b1;
                                  else data_mem_we = 1'b0;
        endcase
    end

    // "Decode" the branch target
    reg [31:0] branch_target;
    always @(*) begin
        branch_target = pc + 8 + inst_branch_imm(inst);
    end

    // "Execute" the instruction
    reg [31:0] alu_result;
    always @(*) begin
        alu_result = 32'h0000_0000;
        if (!nreset) begin
            cpsr[cpsr_n] = 1'b0;
            cpsr[cpsr_z] = 1'b0;
            cpsr[cpsr_c] = 1'b0;
            cpsr[cpsr_v] = 1'b0;
        end
        case (inst_opcode(inst))
            opcode_and: alu_result = rf_d1 & operand2;
            opcode_eor: alu_result = rf_d1 ^ operand2;
            opcode_sub: alu_result = rf_d1 - operand2;
            opcode_rsb: alu_result = operand2 - rf_d1;
            opcode_add: alu_result = rf_d1 + operand2;
            opcode_adc: alu_result = rf_d1 + operand2 + cpsr_c;
            opcode_sbc: alu_result = rf_d1 - operand2 + cpsr_c - 1;
            opcode_rsc: alu_result = operand2 - rf_d1 + cpsr_c - 1;
            opcode_tst: begin
                            cpsr[cpsr_n] = (rf_d1 & operand2) < 0;
                            cpsr[cpsr_z] = (rf_d1 & operand2) == 0;
                            cpsr[cpsr_c] = (rf_d1 & operand2) > 32{1'b1};
                            cpsr[cpsr_v] = (rf_d1 & operand2) > 32'h7fffffff};
                        end
            opcode_teq: begin
                            cpsr[cpsr_n] = (rf_d1 ^ operand2) < 0;
                            cpsr[cpsr_z] = (rf_d1 ^ operand2) == 0;
                            cpsr[cpsr_c] = (rf_d1 ^ operand2) > 32{1'b1};
                            cpsr[cpsr_v] = (rf_d1 ^ operand2) > 32'h7fffffff};
                        end
            opcode_cmp: begin
                            cpsr[cpsr_n] = (rf_d1 - operand2) < 0;
                            cpsr[cpsr_z] = (rf_d1 - operand2) == 0;
                            cpsr[cpsr_c] = (rf_d1 - operand2) > 32{1'b1};
                            cpsr[cpsr_v] = (rf_d1 - operand2) > 32'h7fffffff};
                        end
            opcode_cmpn:begin
                            cpsr[cpsr_n] = (rf_d1 + operand2) < 0;
                            cpsr[cpsr_z] = (rf_d1 + operand2) == 0;
                            cpsr[cpsr_c] = (rf_d1 - operand2) > 32{1'b1};
                            cpsr[cpsr_v] = (rf_d1 - operand2) > 32'h7fffffff};
                        end
            opcode_orr: alu_result = rf_d1 | operand2;
            opcode_mov: alu_result = operand2;
            opcode_bic: begin
                            alu_result = rf_d1 & ~operand2;
                            cpsr[cpsr_n] = 1'b0;
                            cpsr[cpsr_z] = 1'b0;
                            cpsr[cpsr_c] = 1'b0;
                            cpsr[cpsr_v] = 1'b0;
                        end
            opcode_mvn: alu_result = ~operand2;
        endcase
        //calculate data address
        if (inst_type(inst) == inst_type_data_trans) data_addr = rf_d1[4:0] + inst_memoff(inst);
        if (inst_branch_islink(inst)) rf_wd = pc + 4;
        else                          rf_wd = alu_result;
    end

    // "Write back" the instruction
    always @(posedge clk) begin
        if (nreset && rf_we)
            if (rf_ws != r15)
                rf[rf_ws] <= rf_wd;
    end

    // incrament PC
    always @(posedge clk) begin
        if (!nreset)
            pc <= 32'd0;
        else begin
            // default behavior
            //synchronous: create write enable signal
            pc <= pc + 4;

            if (inst_type(inst) == inst_type_branch) begin
                case (inst_cond(inst))
                    cond_eq: (cpsr[cpsr_z] == 1'b1) pc <= branch_target: pc <= pc + 4;
                    cond_ne: (cpsr[cpsr_z] == 1'b0) pc <= branch_target: pc <= pc + 4;
                    cond_cs: (cpsr[cpsr_c] == 1'b1) pc <= branch_target: pc <= pc + 4;
                    cond_cc: (cpsr[cpsr_c] == 1'b0) pc <= branch_target: pc <= pc + 4;
                    cond_ns: (cpsr[cpsr_n] == 1'b1) pc <= branch_target: pc <= pc + 4;
                    cond_nc: (cpsr[cpsr_n] == 1'b0) pc <= branch_target: pc <= pc + 4;
                    cond_vs: (cpsr[cpsr_v] == 1'b1) pc <= branch_target: pc <= pc + 4;
                    cond_vc: (cpsr[cpsr_v] == 1'b0) pc <= branch_target: pc <= pc + 4;
                    cond_hi: ((cpsr[cpsr_c] == 1) & (cpsr[cpsr_z] == 0)) pc <= branch_target: pc <= pc + 4;
                    cond_ls: ((cpsr[cpsr_c] == 1) | (cpsr[cpsr_z] == 0)) pc <= branch_target: pc <= pc + 4;
                    cond_ge: (cpsr[cpsr_n] == cpsr_v) pc <= branch_target: pc <= pc + 4;
                    cond_lt: (cpsr[cpsr_n] != cpsr_v) pc <= branch_target: pc <= pc + 4;
                    cond_gt: ((cpsr[cpsr_z] == 0) & (cpsr[cpsr_n] == cpsr[cpsr_v])) pc <= branch_target: pc <= pc + 4;
                    cond_le: ((cpsr[cpsr_z] == 1) | (cpsr[cpsr_n] != cpsr[cpsr_v])) pc <= branch_target: pc <= pc + 4;
                    cond_al:  pc <= branch_target;
                endcase
                pc <= branch_target;
            end
        end
    end

    //load/store to memory
    always @(posedge clk) begin
        if (data_mem_we) begin
            rf_s1 <= inst_rn(inst);
            data_mem[data_addr] <= rf_d1;
        end
        data_mem_rd <= data_mem[data_addr];
    end

endmodule


// module cpu_testbench();
//     reg clk, resetn;
//     wire led;
//     wire [7:0] debug_port1, debug_port2, debug_port3;
//
//     cpu dut (.clk(clk), .resetn(resetn), .led(led), .debug_port1(debug_port1), .debug_port2(debug_port2), .debug_port3(debug_port3));
//
//     parameter CLOCK_PERIOD=100;
//     initial begin
//         clk <= 0;
//         forever #(CLOCK_PERIOD/2) clk <= ~clk;
//     end
//
//     initial begin
//         resetn <= 0; repeat (3) @(posedge clk);
//         resetn <= 1; repeat(40) @(posedge clk);
//         $stop;
//     end
// endmodule
