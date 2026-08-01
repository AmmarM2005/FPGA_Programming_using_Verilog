module encoder8to3(
    input [7:0]in,
    input en,
    output [2:0]out
);
wire [7:0]w;
and(w[0],in[0],en);
and(w[1],in[1],en);
and(w[2],in[2],en);
and(w[3],in[3],en);
and(w[4],in[4],en);
and(w[5],in[5],en);
and(w[6],in[6],en);
and(w[7],in[7],en);
or(out[0],w[1],w[3],w[5],w[7]);
or(out[1],w[2],w[3],w[6],w[7]);
or(out[2],w[4],w[5],w[6],w[7]);
endmodule