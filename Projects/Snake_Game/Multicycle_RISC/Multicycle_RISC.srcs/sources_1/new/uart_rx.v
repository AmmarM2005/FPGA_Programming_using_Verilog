`timescale 1ns/1ps
// UART receiver 8N1. valid stays 1 until 'ack' pulses.
module uart_rx #(parameter CLKS_PER_BIT = 868)(
    input        clk, rst, rx, ack,
    output reg       valid,
    output reg [7:0] data
);
    reg [1:0] s = 2'b11;
    always @(posedge clk) s <= {s[0], rx};
    wire rxs = s[1];

    reg        busy;
    reg [15:0] cnt;
    reg [3:0]  bitn;
    reg [7:0]  sh;

    always @(posedge clk) begin
        if (rst) begin
            busy <= 0; valid <= 0; cnt <= 0; bitn <= 0; data <= 0; sh <= 0;
        end else begin
            if (ack) valid <= 0;
            if (!busy) begin
                if (!rxs) begin busy <= 1; cnt <= 0; bitn <= 0; end   // start bit seen
            end else if (bitn == 0) begin                              // wait to middle of start bit
                if (cnt == CLKS_PER_BIT/2) begin
                    cnt <= 0;
                    if (rxs) busy <= 0; else bitn <= 1;                // false start -> abort
                end else cnt <= cnt + 1;
            end else begin
                if (cnt == CLKS_PER_BIT-1) begin
                    cnt <= 0;
                    if (bitn == 9) begin busy <= 0; data <= sh; valid <= 1; end  // stop bit
                    else begin sh <= {rxs, sh[7:1]}; bitn <= bitn + 1; end
                end else cnt <= cnt + 1;
            end
        end
    end
endmodule