module cpu(
  input wire clk,
  input wire resetn,
  output wire led,
  output wire [7:0] debug_port1,
  output wire [7:0] debug_port2,
  output wire [7:0] debug_port3
  );

//this part has to do with memory, not related to lab 1 up to line 36
localparam data_width = 32;
localparam data_width_l2b = $clog2(data_width / 8);
localparam data_words = 512;
localparam data_words_l2 = $clog2(data_words);
localparam data_addr_width = data_words_l2;

  reg [data_width - 1:0]  data_mem[data_words - 1:0];
  reg [data_width - 1:0]  data_mem_rd;
  reg [data_width - 1:0]  data_mem_wd;
  reg [data_addr_width - 1:0] data_addr;
  reg data_mem_we;

  always @(posedge clk) begin
    if (data_mem_we)
        data_mem[data_addr] <= data_mem_wd;
    data_mem_rd <= data_mem[data_addr];
  end

localparam code_width = 32;
localparam code_width_l2b = $clog2(data_width / 8);
localparam code_words = 512;
localparam code_words_l2 = $clog2(data_words);
localparam code_addr_width = code_words_l2 - code_width_l2b;
  reg [code_width - 1:0]  code_mem[data_words - 1:0];
  reg [code_width - 1:0]  code_mem_rd;
  wire [code_addr_width - 1:0] code_addr;

    //instructions go here, each code_mem is an instrcution to be decoded
  initial begin
    code_mem[0] = 32'b10001011000_00110_000000_00101_00011; //ADD X3, X5, X6 (458, X6,0,X5,X3)
    code_mem[1] = 32'b000101_00000000000000000000000011;    //Branch: set to jump by 3
    code_mem[2] = 32'b10001011000_00111_000000_00101_00011; //ADD X3, X5, X7 (458, X6,0,X5,X3)
    code_mem[3] = 32'b10001011000_00111_000000_00101_00011;
    code_mem[4] = 32'b10001011000_00111_000000_00101_00011;
    code_mem[5] = 32'b10001011000_00111_000000_00101_00011;
    code_mem[6] = 32'b000101_11111111111111111111111101;    //Branch: set to jump by -3
  end

  always @(posedge clk) begin
    code_mem_rd <= code_mem[code_addr];
  end

  reg [29:0]  pc;

  assign led = pc[1]; // make the LED blink on the low order bit of the PC

  //ports for the debugger script
  assign debug_port1 = pc[7:0];    //program counter
  assign debug_port2 = rf_d1[7:0]; //read the from register - 1
  assign debug_port3 = rf_d2[7:0]; //read the from register - 2

  assign code_addr = pc[code_addr_width - 1:0];

  //the register file is created here
  reg [31:0] rf[0:31];
  reg [31:0] rf_d1; //read data 1
  reg [31:0] rf_d2; //read data 2
  reg [4:0] rf_rs1; //read register 1, select on mux
  reg [4:0] rf_rs2; //read register 2, select on mux
  reg [4:0] rf_ws;  //register select on decoder
  reg [31:0] rf_wd; //write data onto selected register
  reg rf_we;        //register write, enables decoder

  //write bogus data to register, just so we can read afterwards through debug ports
  initial begin
    rf_we = 1'b1;
    rf_ws = 5'b00100;
    rf_wd = 32'h111111E7;
    rf_rs1 = 5'b00100;
    rf_rs2 = 5'b00100;
  end

  always @(posedge clk) begin
    rf_d1 <= rf[rf_rs1];
    rf_d2 <= rf[rf_rs2];
    if (!resetn && rf_we)
      rf[rf_ws] <= rf_wd;
  end

  always @(posedge clk) begin
    data_mem_wd <= 0;
    data_addr <= 0;
//   code_addr <= 0;
    data_mem_we <= 0;
    if (!resetn) begin
      pc <= 0;
    end else begin
      data_addr <= pc;

      // this section is commented out for now
      // this replace above initial statement
      // rf_rs1 <= code_mem_rd[4:0];
      // rf_rs2 <= code_mem_rd[9:5];
      // rf_ws <= code_mem_rd[14:10];
      // rf_we <= code_mem_rd[15];
      // rf_wd <= code_mem_rd;

      // program counter
      if (pc > 6)
        pc <= 0;
      else if(code_mem[pc][31:26] == 6'b000101 & code_mem[pc][25] == 1'b0) //check if opcode is branch with positive jump
        pc <= pc + 1 * (code_mem[pc][25:0]);
      else if(code_mem[pc][31:26] == 6'b000101 & code_mem[pc][25] == 1'b1) //check if opcode is branch with negative jump
        pc <= pc - 1 * (-code_mem[pc][25:0]);
      else // if opcode is ADD then only increment by one
        pc <= pc + 1;   //rf_d1 + rf_d2 + 1;
    end
  end

endmodule
