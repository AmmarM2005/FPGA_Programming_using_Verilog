module decoder2to4(
    input [1:0]in,
    input en,
    output [3:0]out
);
wire [3:0]w;
and(w[0],~in[1],~in[0]);
and(w[1],~in[1],in[0]);
and(w[2],in[1],~in[0]);
and(w[3],in[1],in[0]);
and(out[0],w[0],en);
and(out[1],w[1],en);
and(out[2],w[2],en);
and(out[3],w[3],en);
endmodule