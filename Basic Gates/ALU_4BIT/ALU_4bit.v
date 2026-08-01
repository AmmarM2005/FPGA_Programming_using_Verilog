module ALU_4bit(
    A,B, OPCODE, Y
);
input [3:0]A;
input [3:0]B; 
input [2:0]OPCODE;
output reg [7:0]Y;
always@(*)begin
case({OPCODE[2],OPCODE[1],OPCODE[0]})
3'b000:Y=A+B;
3'b001:Y=A-B;
3'b010:Y=A*B;
3'b011:Y=A/B;
3'b100:Y=A&B;
3'b101:Y=A|B;
3'b110:Y=A<B;
3'b111:Y=A%B;
endcase
end
endmodule