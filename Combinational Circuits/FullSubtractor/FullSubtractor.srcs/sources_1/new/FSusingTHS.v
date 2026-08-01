module full_subtractor(input a,b,cin,output d,bo);
    wire w1,w2,w3;
    half_subtractor_gate A1(a,b,w1,w2);
    half_subtractor_gate A2(w2,cin,d,w3);
    or(bo,w2,w3);
endmodule