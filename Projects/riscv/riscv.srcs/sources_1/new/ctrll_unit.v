module CU(
input [6:0] opcode,
output reg RegWrite, ALUSrc, MemRead, MemWrite,
output reg        ALUSrcA,      // ← NEW: 0=rs1, 1=PC
output reg [1:0] ResultSrc,     // 00=ALU 01=MEM 10=PC+4
output reg        jalr,         // FIX: 1 only for JALR target = rs1+imm
output reg Branch, Jump,
output reg [1:0] ALUOp
);
always @(*) begin
RegWrite=0; ALUSrc=0; MemRead=0; MemWrite=0;ALUSrcA=0;
ResultSrc=2'b00; Branch=0; Jump=0; ALUOp=2'b00; jalr=0;
case(opcode)
7'b0110011: begin RegWrite=1; ALUSrc=0; ALUOp=2'b10; end    // R
7'b0010011: begin RegWrite=1; ALUSrc=1; ALUOp=2'b11; end    // I-ALU
7'b0000011: begin RegWrite=1; ALUSrc=1; MemRead=1;          // LOAD
ResultSrc=2'b01; ALUOp=2'b00; end
7'b0100011: begin ALUSrc=1; MemWrite=1; ALUOp=2'b00; end    // STORE
7'b1100011: begin Branch=1; ALUOp=2'b01; end                // BRANCH
7'b0110111: begin RegWrite=1; ResultSrc=2'b11; end          // LUI
// AUIPC   FIX: ALUSrcA=1 uses PC, not rs1
            7'b0010111: begin
                RegWrite=1; ALUSrcA=1; ALUSrc=1; ALUOp=2'b00;
                // ALU: PC + imm
            end
7'b1101111: begin RegWrite=1; Jump=1; ResultSrc=2'b10; end // JAL
// JALR    FIX: jalr=1 - target = rs1 + imm
            7'b1100111: begin
                RegWrite=1; ALUSrc=1; Jump=1;
                ResultSrc=2'b10; jalr=1;
                // ALUOp=00 - ALU adds rs1+imm for target address
            end
endcase
end
endmodule