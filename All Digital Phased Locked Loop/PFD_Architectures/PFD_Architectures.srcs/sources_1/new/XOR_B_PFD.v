module XOR_B_PFD (
    input clk_ref,
    input clk_fb,
    output up
);

assign up = clk_ref ^ clk_fb;

endmodule