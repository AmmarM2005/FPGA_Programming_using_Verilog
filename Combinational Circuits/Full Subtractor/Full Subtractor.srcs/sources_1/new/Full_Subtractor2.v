module full_subtractor(
    input a,b,c,
    output diff,bo
);
wire w1,w2,w3;
xor(w1,a,b);
xor(diff,w1,c);
and(w2,~w1,c);
and(w3,~a,b);
or(bo,w2,w3);
endmodule