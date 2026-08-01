module DPA(
    input in,
    output out
);

wire w1;
wire w2;
wire w3;
wire w4;
wire w5;
wire w6;

and g1(w1, in, in);
and g2(w2, w1, w1);
and g3(w3, w2, w2);
and g4(w4, w3, w3);
and g5(w5, w4, w4);
and g6(w6, w5, w5);
and g7(out, w6, w6);

endmodule