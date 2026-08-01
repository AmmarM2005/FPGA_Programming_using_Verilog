module jk_ff (
    input clk, rst,
    input j, k,
    output reg q
);

    initial begin
        q = 1'b0;
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) q <= 1'b0;
        else case ({j, k})
            2'b00: q <= q;     
            2'b01: q <= 1'b0;  
            2'b10: q <= 1'b1;  
            2'b11: q <= ~q;    
        endcase
    end
endmodule