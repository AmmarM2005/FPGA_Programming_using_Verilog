`timescale 1ns/1ps
// ============================================================
// Basys 3 top level: wraps the CPU so only real board pins are used.
//
//   clk        100 MHz clock
//   rst        center button (btnC), active high
//   sw[4:0]    register number shown on the LEDs
//   sw[14]     0 = show the selected register, 1 = show the PC
//   sw[15]     0 = show bits [15:0], 1 = show bits [31:16]
//   led[15:0]  the 16 bits selected by the switches
// ============================================================
module basys3_top (
    input         clk,
    input         rst,
    input  [15:0] sw,
    output [15:0] led
);
    // synchronize the button to the clock (2 flip-flops)
    reg [1:0] rst_sync = 2'b11;
    always @(posedge clk) rst_sync <= {rst_sync[0], rst};
    wire rst_s = rst_sync[1];

    wire [31:0] reg_data;
    wire [31:0] pc;

    cpu u_cpu (
        .clk          (clk),
        .rst          (rst_s),
        .dbg_reg_sel  (sw[4:0]),
        .dbg_reg_data (reg_data),
        .dbg_pc       (pc)
    );

    wire [31:0] shown = sw[14] ? pc : reg_data;
    assign led = sw[15] ? shown[31:16] : shown[15:0];
endmodule
