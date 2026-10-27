`timescale 1ns/1ps
// ============================================================
// UART transmitter, 8 data bits, no parity, 1 stop bit (8N1).
// 100 MHz clock / 115200 baud = 868 clocks per bit.
//   start = 1 for one clock with 'data' valid -> sends the byte
//   busy  = 1 while a byte is being sent (a 'start' while busy is ignored)
// ============================================================
module uart_tx #(
    parameter CLKS_PER_BIT = 868
)(
    input        clk,
    input        rst,
    input  [7:0] data,
    input        start,
    output       busy,
    output       tx
);
    reg [9:0]  shifter = 10'h3FF;       // {stop, data[7:0], start}
    reg [3:0]  bit_cnt = 4'd0;          // bits left to send
    reg [15:0] clk_cnt = 16'd0;
    reg        sending = 1'b0;

    assign busy = sending;
    assign tx   = shifter[0];           // idle level = 1

    always @(posedge clk) begin
        if (rst) begin
            shifter <= 10'h3FF;
            sending <= 1'b0;
            bit_cnt <= 4'd0;
            clk_cnt <= 16'd0;
        end else if (!sending) begin
            if (start) begin
                shifter <= {1'b1, data, 1'b0};
                sending <= 1'b1;
                bit_cnt <= 4'd10;
                clk_cnt <= 16'd0;
            end
        end else begin
            if (clk_cnt == CLKS_PER_BIT - 1) begin
                clk_cnt <= 16'd0;
                shifter <= {1'b1, shifter[9:1]};     // next bit (fills with 1s)
                if (bit_cnt == 4'd1) sending <= 1'b0;
                bit_cnt <= bit_cnt - 4'd1;
            end else
                clk_cnt <= clk_cnt + 16'd1;
        end
    end
endmodule