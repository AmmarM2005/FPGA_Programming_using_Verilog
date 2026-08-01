module RAM_8_8 (
    input clk,
    input [2:0] addr,     
    input [7:0] data_in,  
    input we,             
    output reg [7:0] data_out 
);
    reg [7:0] memory [0:7];
    integer i;
    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            memory[i] = 8'b0;
        end
    end
    always @(posedge clk) begin
        if (we) begin
            memory[addr] <= data_in;
        end
    end
    always @(*) begin
        data_out = memory[addr];
    end
endmodule