`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.11.2025 09:22:56
// Design Name: 
// Module Name: Test_Counter_4bit
// Project Name: 
// Target Devices: 
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
module Test_Counter_4bit(
    input clk,
    input rst,
    output reg [3:0] Y
    );
   always @(posedge clk, posedge rst)begin
    if (rst)
        Y <= 4'd0;
    else
        Y <= Y + 4'd1;
   end
endmodule
