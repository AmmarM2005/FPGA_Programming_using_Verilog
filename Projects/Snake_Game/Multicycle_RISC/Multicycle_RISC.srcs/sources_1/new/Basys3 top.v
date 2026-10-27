`timescale 1ns/1ps
// ============================================================
// Basys 3 top level.
//   clk        100 MHz clock
//   rst        center button (btnC), active high
//   sw[4:0]    register number shown on the LEDs
//   sw[14]     0 = show the selected register, 1 = show the PC
//   sw[15]     0 = show bits [15:0], 1 = show bits [31:16]
//   led[15:0]  the 16 bits selected by the switches
//   btnU/D/L/R direction buttons (read by the program at 0x4000000C)
//   uart_tx    serial output to the PC (115200 baud, 8N1)
//   uart_rxd   serial input from the PC (115200 baud, 8N1)
// ============================================================
module basys3_top (
    input         clk,
    input         rst,
    input  [15:0] sw,
    input         btnU, btnD, btnL, btnR,
    input         uart_rxd,
    output [15:0] led,
    output        uart_tx
);
    // synchronize the reset button to the clock (2 flip-flops)
    reg [1:0] rst_sync = 2'b11;
    always @(posedge clk) rst_sync <= {rst_sync[0], rst};
    wire rst_s = rst_sync[1];

    // synchronize the direction buttons (2 flip-flops)
    reg [3:0] b1 = 4'b0, b2 = 4'b0;
    always @(posedge clk) begin
        b1 <= {btnU, btnD, btnL, btnR};
        b2 <= b1;
    end

    wire [31:0] reg_data;
    wire [31:0] pc;
    wire [7:0]  uart_wdata;
    wire        uart_wr, uart_busy;
    wire [7:0]  rx_data;
    wire        rx_valid, rx_ack;

    cpu u_cpu (
        .clk          (clk),
        .rst          (rst_s),
        .dbg_reg_sel  (sw[4:0]),
        .dbg_reg_data (reg_data),
        .dbg_pc       (pc),
        .uart_wdata   (uart_wdata),
        .uart_wr      (uart_wr),
        .uart_busy    (uart_busy),
        .rx_data      (rx_data),
        .rx_valid     (rx_valid),
        .rx_ack       (rx_ack),
        .btn          (b2)
    );

    uart_tx #(.CLKS_PER_BIT(868)) u_uart (
        .clk   (clk),
        .rst   (rst_s),
        .data  (uart_wdata),
        .start (uart_wr),
        .busy  (uart_busy),
        .tx    (uart_tx)
    );

    uart_rx #(.CLKS_PER_BIT(868)) u_rx (
        .clk   (clk),
        .rst   (rst_s),
        .rx    (uart_rxd),
        .ack   (rx_ack),
        .valid (rx_valid),
        .data  (rx_data)
    );

    wire [31:0] shown = sw[14] ? pc : reg_data;
    assign led = sw[15] ? shown[31:16] : shown[15:0];
endmodule