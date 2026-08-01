`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  AM_Industries
// Engineer: Ammar Maheshwarwala
// 
// Create Date: 28.11.2025 09:16:22
// Design Name: 
// Module Name: Main_Counter
// Project Name: ATPG For 4 bit Counter
// Target Devices: Basys 3
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module main_Counter_4bit(
    input clk,
    input rst,
    input dir,
    input ld,
    input [3:0] d_in,
    output reg [3:0] Y
    );
   always @(posedge clk, posedge rst)begin
    if (rst)
        Y <= 4'd0;
    else
        if (ld)
            Y<= d_in;
        else
            if (dir)
                Y <= Y+ 4'd1;
            else
                Y <= Y - 4'd1;
   end
endmodule
