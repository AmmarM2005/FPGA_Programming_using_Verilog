module DataMem (
    input         clk, MemWrite, MemRead,
    input  [31:0] addr, write_data,
    output [31:0] read_data
);
    reg [31:0] mem [0:255];

    // Initialize ALL memory to 0 at simulation start
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'b0;
    end

    assign read_data = (MemRead) ? mem[addr >> 2] : 32'b0;

    always @(posedge clk) begin
        if (MemWrite)
            mem[addr >> 2] <= write_data;
    end
endmodule
