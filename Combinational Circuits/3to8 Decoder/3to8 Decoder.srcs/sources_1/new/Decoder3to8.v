module decoder3to8(
    input [2:0]in,
    input en,
    output [7:0]out
);
wire [7:0]w;
and(w[0],~in[2],~in[1],~in[0]);
and(w[1],~in[2],~in[1],in[0]);
and(w[2],~in[2],in[1],~in[0]);
and(w[3],~in[2],in[1],in[0]);
and(w[4],in[2],~in[1],~in[0]);
and(w[5],in[2],~in[1],in[0]);
and(w[6],in[2],in[1],~in[0]);
and(w[7],in[2],in[1],in[0]);
and(out[0],w[0],en);
and(out[1],w[1],en);
and(out[2],w[2],en);
and(out[3],w[3],en);
and(out[4],w[4],en);
and(out[5],w[5],en);
and(out[6],w[6],en);
and(out[7],w[7],en);
endmodule