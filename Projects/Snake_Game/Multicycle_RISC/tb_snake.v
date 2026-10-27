`timescale 1ns/1ps
// ============================================================
// Board-free test of the snake game (no Basys 3 needed).
// Runs the CPU + UART with a FAST baud rate (4 clocks/bit instead of 868),
// captures every byte the game sends, and presses keys over the RX line.
// Output: uart_out.bin  (raw terminal bytes, incl. ANSI codes)
// ============================================================
module tb_snake;
  localparam CPB = 4;                    // clocks per UART bit (board uses 868)
  reg clk = 0, rst = 1, rxd = 1;
  reg [3:0] btn = 0;                     // {btnU, btnD, btnL, btnR}
  wire [7:0] wd; wire wr, busy, tx;
  wire [7:0] rd; wire rv, ack;
  wire [31:0] pc, regd;
  integer fd;
  always #5 clk = ~clk;

  cpu dut(.clk(clk), .rst(rst), .dbg_reg_sel(5'd0), .dbg_reg_data(regd), .dbg_pc(pc),
          .uart_wdata(wd), .uart_wr(wr), .uart_busy(busy),
          .rx_data(rd), .rx_valid(rv), .rx_ack(ack), .btn(btn));
  uart_tx #(.CLKS_PER_BIT(CPB)) t(.clk(clk), .rst(rst), .data(wd), .start(wr), .busy(busy), .tx(tx));
  uart_rx #(.CLKS_PER_BIT(CPB)) r(.clk(clk), .rst(rst), .rx(rxd), .ack(ack), .valid(rv), .data(rd));

  always @(posedge clk) if (wr) $fwrite(fd, "%c", wd);   // log game output

  task send(input [7:0] b); integer i; begin           // act like a PC typing a key
    rxd = 0; repeat (CPB) @(posedge clk);
    for (i = 0; i < 8; i = i + 1) begin rxd = b[i]; repeat (CPB) @(posedge clk); end
    rxd = 1; repeat (CPB) @(posedge clk);
  end endtask

  initial begin
    fd = $fopen("uart_out.bin", "wb");
    repeat (5) @(posedge clk); rst = 0;
    repeat (200000)   @(posedge clk);  send("s");       // steer DOWN
    repeat (12000000) @(posedge clk);  send("d");       // steer RIGHT
    repeat (12000000) @(posedge clk);
    // btn = 4'b0010;  // example: hold btnL   (uncomment to test the buttons)
    $fclose(fd); $display("simulation finished"); $finish;
  end
endmodule
