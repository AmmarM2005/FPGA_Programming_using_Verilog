module pc(input clk,input rst,input [31:0] next_pc,output reg [31:0] pc);
always @(posedge clk or posedge rst)
if(rst) 
    pc<=0;
else 
    pc<=next_pc;
endmodule