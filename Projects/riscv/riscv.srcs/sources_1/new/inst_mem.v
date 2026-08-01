module im (
    input  [31:0] pc,
    output [31:0] inst
);
    reg [31:0] memory [0:255];

    // Initialize to NOP (addi x0, x0, 0 = 0x00000013) first,
    // THEN load your program on top of it.
    // Any unfilled slots become NOP instead of X.
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            memory[i] = 32'h00000013;   // NOP instruction
        $readmemh("program.mem", memory);
    end

    assign inst = memory[pc[9:2]];
endmodule