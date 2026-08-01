module reg_file(input clk,input we,input [4:0]rs1,rs2,rd,input [31:0]wd,output [31:0]rd1,rd2);
reg [31:0] regf[0:31];
assign rd1=regf[rs1];
assign rd2=regf[rs2];
always @(posedge clk)
if(we && rd!=0) 
    regf[rd]<=wd;
endmodule