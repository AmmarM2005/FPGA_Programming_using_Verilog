`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////


module alu_8bit(
    input [7:0] A,
    input [7:0] B,
    input [2:0] OP,
    output reg [15:0] result
    );
   parameter add = 3'b000,
             sub = 3'b001,
             mul = 3'b010,
             Inv = 3'b011,
             And = 3'b100,
             Or  = 3'b101,
             Xor = 3'b110,
             Sll = 3'b111;
  always @(A,B,OP) begin
    case (OP)
       add :
                result = {8'h00,A} +{8'h00,B};   
       sub :    
                result = {8'h00,A} - {8'h00,B};
       mul  :
                result = A * B;
       Inv  : 
                result = {8'h00,~A} ;
       And  :
                result = {8'h00,A} & {8'h00,B};
       Or   :   
                result = {8'h00,A} | {8'h00,B};
       Xor  :
                result = {8'h00,A} ^ {8'h00,B};
       default  : 
                 result = {8'h00,A} << B;         
       endcase
      end                                                            
endmodule