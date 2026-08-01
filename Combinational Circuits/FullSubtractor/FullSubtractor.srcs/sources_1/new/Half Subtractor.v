module half_subtractor_gate(input a,b,output d,bo);
    xor(d,a,b);
    wire not_a;
    not(not_a,a);
    and(bo,not_a,b);
endmodule
