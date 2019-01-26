module top (
  input  pin_clk,

  inout  pin_usb_p,
  inout  pin_usb_n,
  output pin_pu,

  output pin_led

  );

  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////
  //////// generate 48 mhz clock
  ////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  wire clk_48mhz;

// OUT = Input X (DIVF + 1) / (2^(DIVQ) X (DIVR + 1))
// Input = 16Mhz
// OUT = 16Mhz X 96 / (2^4 * 1) = 
  SB_PLL40_CORE #(
    .DIVR(4'b0000),
    .DIVF(7'b0101111),
    .DIVQ(3'b100),
    .FILTER_RANGE(3'b001),
    .FEEDBACK_PATH("SIMPLE"),
    .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
    .FDA_FEEDBACK(4'b0000),
    .DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
    .FDA_RELATIVE(4'b0000),
    .SHIFTREG_DIV_MODE(2'b00),
    .PLLOUT_SELECT("GENCLK"),
    .ENABLE_ICEGATE(1'b0)
  ) usb_pll_inst (
    .REFERENCECLK(pin_clk),
    .PLLOUTCORE(clk_48mhz),
    .PLLOUTGLOBAL(),
    .EXTFEEDBACK(),
    .DYNAMICDELAY(),
    .RESETB(1'b1),
    .BYPASS(1'b0),
    .LATCHINPUTVALUE(),
    .LOCK(),
    .SDI(),
    .SDO(),
    .SCLK()
  );

  // Generate reset signal (48Mhz clock domain)
  reg   [12:0] reset_cnt = 0;
  wire  resetn = &reset_cnt;
  always @(posedge clk_48mhz) reset_cnt <= reset_cnt + !resetn;

  // Generate the slow speed clock
  localparam slow_clock_size = 23;
  reg [slow_clock_size:0]  slow_clock;
  wire clk_a1hz;
  always @(posedge clk_48mhz) slow_clock <= slow_clock + 1;
  assign clk_a1hz = slow_clock[slow_clock_size];

  // Generate the slow speed reset signal
  reg   [4:0] slow_reset_cnt = 0;
  wire  slow_resetn = &slow_reset_cnt;
  always @(posedge clk_a1hz) slow_reset_cnt <= slow_reset_cnt + !slow_resetn;

  localparam debug_bytes = 4; // must be power of two
  localparam debug_bytes_l2 = $clog2(debug_bytes);

  reg [7:0] data[0:debug_bytes - 1];
  wire [7:0] data_wd[0:debug_bytes - 1];
  reg [debug_bytes_l2:0] byte_output_count;

  // Data from the debugger
  reg [7:0] uart_out_data;
  wire uart_out_valid;
  reg uart_out_ready;

  // Data being sent to the debugger
  reg [7:0] uart_in_data;
  reg uart_in_valid;
  wire uart_in_ready;

// Send data to the USB port for debugging
  always @(posedge clk_a1hz) begin
    data[0] <= data[0] + 1; // Delete this if you don't want a slow speed cycle counter, but it's highly recommended.

    data[1] <= data_wd[1]; 
    data[2] <= data_wd[2];
    data[3] <= data_wd[3];
  end


  cpu the_cpu(clk_a1hz, slow_resetn, pin_led, data_wd[1], data_wd[2], data_wd[3]);


// Out delay slows down output to the serial port.  The CPU runs at ~ 1Hz
// so no need to spam at 12Mbits/second :).  Spamming at full speed
// also causes bytes to fall on the floor because the python debugger
// can't read the usb port that fast.
localparam out_delay_max  = 15;
reg [out_delay_max:0]   out_delay;

always @(posedge clk_48mhz) begin
    if (!resetn) begin
        byte_output_count <= 0;
        out_delay <= 0;
    end
    else begin
        // Always see if there is a ready byte.  If there is, take it.
        if (uart_out_valid)
            uart_out_ready <= 1;
        else
            uart_out_ready <= 0;

        out_delay <= out_delay + 1;
        if (uart_in_ready && out_delay == 0) begin
            if (byte_output_count[debug_bytes_l2])
              uart_in_data <= 8'b11111111;
            else
              uart_in_data <= data[byte_output_count[debug_bytes_l2 - 1:0]];
            byte_output_count <= byte_output_count + 1;
            uart_in_valid <= 1;
        end else
          uart_in_valid <= 0;
    end
end

 // usb uart - this instantiates the entire USB device.
  usb_uart_i40 uart (
    .clk_48mhz  (clk_48mhz),
    .reset      (!resetn),

    // pins
    .pin_usb_p( pin_usb_p ),
    .pin_usb_n( pin_usb_n ),

    // uart pipeline in
    .uart_in_data( uart_in_data ),
    .uart_in_valid( uart_in_valid ),
    .uart_in_ready( uart_in_ready ),

    .uart_out_data( uart_out_data ),
    .uart_out_valid( uart_out_valid ),
    .uart_out_ready( uart_out_ready  )
  );

  // The commented out code would cause the USB port to drop
  // off the USB bus during reset.  Doesn't seem necessary.
  assign pin_pu = 1'b1;//(resetn) ? 1'b 1 : 1'bz;


endmodule
