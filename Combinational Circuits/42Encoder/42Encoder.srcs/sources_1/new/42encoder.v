module encoder4to2(
    input [3:0]in,
    input en,
    output [1:0]out
);
wire [3:0]w;
and(w[0],in[0],en);
and(w[1],in[1],en);
and(w[2],in[2],en);
and(w[3],in[3],en);
or(out[0],w[1],w[3]);
or(out[1],w[2],w[3]);
endmodule