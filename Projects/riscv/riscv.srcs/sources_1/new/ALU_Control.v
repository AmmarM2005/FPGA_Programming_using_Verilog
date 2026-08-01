module alu_control(
    input  [1:0] aluop,
    input  [2:0] f3,
    input        f7,
    output reg [3:0] alu_c
);
    always @(*) begin
        case (aluop)

            2'b00: begin
                // LOAD / STORE - always ADD regardless of f3/f7
                alu_c = 4'b0010;
            end

            2'b01: begin
                // BRANCH - always SUB regardless of f3/f7
                // zero flag then tells us if rs1 == rs2
                alu_c = 4'b0110;
            end

            2'b10: begin
                // R-TYPE - use both f3 and f7
                case (f3)
                    3'b000: alu_c = f7 ? 4'b0110 : 4'b0010; // sub : add
                    3'b001: alu_c = 4'b1000;  // sll
                    3'b010: alu_c = 4'b0111;  // slt
                    3'b100: alu_c = 4'b0011;  // xor
                    3'b101: alu_c = f7 ? 4'b1010 : 4'b1001; // sra : srl
                    3'b110: alu_c = 4'b0001;  // or
                    3'b111: alu_c = 4'b0000;  // and
                    default: alu_c = 4'b0010;
                endcase
            end

            2'b11: begin
                // I-TYPE ALU - use f3 only, f7 ignored
                case (f3)
                    3'b000: alu_c = 4'b0010;  // addi
                    3'b010: alu_c = 4'b0111;  // slti
                    3'b100: alu_c = 4'b0011;  // xori
                    3'b110: alu_c = 4'b0001;  // ori
                    3'b111: alu_c = 4'b0000;  // andi
                    default: alu_c = 4'b0010;
                endcase
            end

            default: alu_c = 4'b0010;
        endcase
    end
endmodule