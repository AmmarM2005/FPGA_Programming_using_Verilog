module PC_n(
input clk, rst,
input branch, zero,
input jump,
input [31:0] imm,
input [31:0] pc_in, // current PC value fed in from top
output reg [31:0] pc
);
wire [31:0] pc_plus4 = pc_in + 4;
wire [31:0] pc_target = pc_in + imm;
wire [31:0] next_pc = (jump || (branch && zero)) ? pc_target : pc_plus4;
always @(posedge clk or posedge rst) begin
if (rst) pc <= 32'h0;
else pc <= next_pc;
end
endmodule