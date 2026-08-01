module half_subtractor(
    input a,b,
    output diff,bo
);
xor(diff,a,b);
and(bo,~a,b);
endmodule