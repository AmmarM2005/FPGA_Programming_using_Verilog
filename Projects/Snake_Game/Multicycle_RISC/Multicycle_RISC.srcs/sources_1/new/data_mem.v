`timescale 1ns/1ps
// Data memory: 2048 words (8 KB). Loaded from program.mem so that
// strings (.rodata) and initialised variables (.data) are visible to lb/lw.
module DataMem (
    input         clk, MemWrite, MemRead,
    input  [2:0]  funct3,          // 000 b, 001 h, 010 w, 100 bu, 101 hu
    input  [31:0] addr, write_data,
    output [31:0] read_data
);
    reg [31:0] mem [0:2047];

    integer i;
    initial begin
        for (i = 0; i < 2048; i = i + 1)
            mem[i] = 32'b0;
        $readmemh("program.mem", mem, 0, 2047);
    end

    wire [1:0]  off  = addr[1:0];
    wire [10:0] widx = addr[12:2];          // word index (8 KB)
    wire [31:0] word = mem[widx];

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

    assign read_data = MemRead ? rdata : 32'b0;

    // ---------------- write: only the addressed byte(s) change ----------------
    always @(posedge clk) begin
        if (MemWrite) begin
            case (funct3[1:0])
                2'b00: case (off)                                   // sb
                    2'd0: mem[widx][7:0]   <= write_data[7:0];
                    2'd1: mem[widx][15:8]  <= write_data[7:0];
                    2'd2: mem[widx][23:16] <= write_data[7:0];
                    2'd3: mem[widx][31:24] <= write_data[7:0];
                endcase
                2'b01: if (off[1]) mem[widx][31:16] <= write_data[15:0]; // sh
                       else        mem[widx][15:0]  <= write_data[15:0];
                default: mem[widx] <= write_data;                        // sw
            endcase
        end
    end
endmodule