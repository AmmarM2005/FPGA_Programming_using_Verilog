module ImmGen(
input [31:0] inst,
output reg [31:0] imm
);
always @(*) begin
case (inst[6:0])
7'b0010011, 7'b0000011, 7'b1100111:
imm = {{20{inst[31]}}, inst[31:20]}; // I-type
7'b0100011:
imm = {{20{inst[31]}}, inst[31:25], inst[11:7]}; // S-type
7'b1100011: // B-type 
imm = {{19{inst[31]}}, inst[31], inst[7],
inst[30:25], inst[11:8], 1'b0};
7'b0110111, 7'b0010111:
imm = {inst[31:12], 12'b0}; // U-type
7'b1101111:
imm = {{11{inst[31]}}, inst[31], inst[19:12],
inst[20], inst[30:21], 1'b0}; // J-type
default: imm = 32'b0;
endcase
end
endmodule