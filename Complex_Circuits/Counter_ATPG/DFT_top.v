`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.11.2025 09:26:35
// Design Name: 
// Module Name: DFT_top
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


module DFT_top(
    input clk,
    input rst,
    input Id,
    input dir,
    input Test_Mode,
    input [3:0] d_in,
    output [3:0] Y
    );
    
    wire clk_t, rst_t, dir_t, Id_t;
    wire [3:0]data_in_t;
    wire clk_in, rst_in, Id_in, dir_in;
    wire [3:0] data_in;
    wire [3:0]Y_out;
    
    reg [3:0] pattern_gen; 
    
    main_Counter_4bit DUT1(clk_in, rst_in, dir_in, Id_in, data_in_Y, Y_out );
    Test_Counter_4bit U1(clk_t,rst_t, data_in_t);
    
    assign clk_in = (Test_Mode)? clk:clk_t;
    assign dir_in = (Test_Mode)? dir:dir_t;
    assign Id_in = (Test_Mode)? Id:Id_t;
    assign rst_in = (Test_Mode)? clk:rst_t;
    assign data_in = (Test_Mode)? d_in:data_in_t;
    
    always @(posedge clk, posedge rst)begin
    if (rst)
        pattern_gen <= 6'd0;
    else
        pattern_gen <= Y + 6'd1;
    end
    assign clk_t= pattern_gen[0];
    assign dir_t= pattern_gen[3];
    assign ld_t= pattern_gen[4];
    assign rst_t= pattern_gen[5];
    assign {Y,Y_t}= (Test_Mode)? {Y_out,4'b0000} : {4'b0000,Y_out};
    
endmodule
