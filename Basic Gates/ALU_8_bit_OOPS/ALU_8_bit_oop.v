module ALU_8_bit(
    input [7:0]A, input [7:0]B, input[2:0]OP, output reg [15:0]R
    );
    parameter   add = 3'b001;
    parameter   sub = 3'b001;
    parameter   mul = 3'b010;
    parameter   Inv = 3'b011;
    parameter   And = 3'b100;
    parameter   Or  = 3'b101;
    parameter   Xor = 3'b110; 
                
    always@(A,B,OP) begin
        case(OP)
            
            add:R = {8'h00,A}+{8'h00,B};
            sub:R = {8'h00,A}-{8'h00,B};
            mul:R = A*B;
            Inv:R = {8'h00,~A};
            And:R = {8'h00,A}&{8'h00,B};
            Or:R = {8'h00,A}|{8'h00,B};
            default:R = {8'h00,A}^{8'h00,B};
        endcase
        end
endmodule
