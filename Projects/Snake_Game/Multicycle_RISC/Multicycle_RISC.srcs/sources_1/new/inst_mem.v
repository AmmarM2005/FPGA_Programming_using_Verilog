`timescale 1ns/1ps
// Instruction memory: 2048 words (8 KB), loaded from program.mem
module im (
    input  [31:0] pc,
    output [31:0] inst
);
    reg [31:0] mem [0:2047];
    integer i;
    initial begin
        for (i = 0; i < 2048; i = i + 1)
            mem[i] = 32'h00000013;          // unused words = nop
        $readmemh("program.mem", mem);
    end
    assign inst = mem[pc[12:2]];
endmodule