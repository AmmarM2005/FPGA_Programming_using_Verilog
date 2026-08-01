module FA_8bit(
    input [7:0] A,
    input [7:0] B,
    input Cin,
    output [7:0] Sum,
    output Cout
);
wire [7:0] C;

assign C[0] = Cin;

genvar i;
generate
for(i=0; i<8; i=i+1) begin
    assign Sum[i] = A[i]^B[i]^C[i];
    assign C[i+1] = (A[i]&B[i]) | (C[i]&(A[i]^B[i]));
end
endgenerate

assign Cout = C[8];

endmodule