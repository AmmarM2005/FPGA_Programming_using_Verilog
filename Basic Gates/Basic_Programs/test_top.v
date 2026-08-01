module test_top(
    input wire a,
    output wire [3:0] out
);

assign out = {4{a}};

endmodule