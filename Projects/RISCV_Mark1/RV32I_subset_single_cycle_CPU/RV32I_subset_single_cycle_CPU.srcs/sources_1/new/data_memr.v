module data_memr(input clk,input we,input [31:0]addr,input [31:0]wd,output [31:0]rd);
reg [31:0] mem[0:255];
assign rd=mem[addr[9:2]];
always @(posedge clk)
if(we) 
    mem[addr[9:2]]<=wd;
endmodule