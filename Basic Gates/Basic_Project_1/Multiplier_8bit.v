module Multiplier_4bit(A,B,Y);
input [3:0]A;
input [3:0]B;
output reg [7:0]Y;
always@(*)begin
Y=A*B;
end
endmodule