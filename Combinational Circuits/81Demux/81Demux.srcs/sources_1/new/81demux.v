module demux1to8(
    input in,
    input [2:0]sel,
    input en,
    output [7:0]out
);
wire [7:0]w;
and(w[0],~sel[2],~sel[1],~sel[0]);
and(w[1],~sel[2],~sel[1],sel[0]);
and(w[2],~sel[2],sel[1],~sel[0]);
and(w[3],~sel[2],sel[1],sel[0]);
and(w[4],sel[2],~sel[1],~sel[0]);
and(w[5],sel[2],~sel[1],sel[0]);
and(w[6],sel[2],sel[1],~sel[0]);
and(w[7],sel[2],sel[1],sel[0]);
and(out[0],w[0],in,en);
and(out[1],w[1],in,en);
and(out[2],w[2],in,en);
and(out[3],w[3],in,en);
and(out[4],w[4],in,en);
and(out[5],w[5],in,en);
and(out[6],w[6],in,en);
and(out[7],w[7],in,en);
endmodule