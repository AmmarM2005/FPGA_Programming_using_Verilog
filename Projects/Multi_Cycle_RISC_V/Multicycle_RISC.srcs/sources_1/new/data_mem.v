`timescale 1ns/1ps
module DataMem (
    input         clk, MemWrite, MemRead,
    input  [2:0]  funct3,          // 000 b, 001 h, 010 w, 100 bu, 101 hu
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

    wire [1:0]  off  = addr[1:0];
    wire [31:0] word = mem[addr >> 2];

    // ---------------- read: pick byte/half, then sign or zero extend ----------------
    wire [7:0]  rb = word >> {off, 3'b000};
    wire [15:0] rh = off[1] ? word[31:16] : word[15:0];

    reg [31:0] rdata;
    always @(*) begin
        case (funct3)
            3'b000:  rdata = {{24{rb[7]}},  rb};   // lb
            3'b001:  rdata = {{16{rh[15]}}, rh};   // lh
            3'b100:  rdata = {24'b0, rb};          // lbu
            3'b101:  rdata = {16'b0, rh};          // lhu
            default: rdata = word;                 // lw
        endcase
    end

    assign read_data = (MemRead) ? rdata : 32'b0;

    // ---------------- write: only the addressed byte(s) change ----------------
    always @(posedge clk) begin
        if (MemWrite) begin
            case (funct3[1:0])
                2'b00: case (off)                              // sb
                    2'd0: mem[addr >> 2][7:0]   <= write_data[7:0];
                    2'd1: mem[addr >> 2][15:8]  <= write_data[7:0];
                    2'd2: mem[addr >> 2][23:16] <= write_data[7:0];
                    2'd3: mem[addr >> 2][31:24] <= write_data[7:0];
                endcase
                2'b01: if (off[1]) mem[addr >> 2][31:16] <= write_data[15:0];   // sh
                       else        mem[addr >> 2][15:0]  <= write_data[15:0];
                default: mem[addr >> 2] <= write_data;                          // sw
            endcase
        end
    end
endmodule