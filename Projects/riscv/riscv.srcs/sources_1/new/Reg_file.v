module Reg_file (
    input         clk,
    input         rst,        
    input         reg_write,
    input  [4:0]  rs1, rs2, rd,
    input  [31:0] write_data,
    output [31:0] read_data1, read_data2
);
    reg [31:0] registers [0:31];

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            registers[i] = 32'b0;
    end

    assign read_data1 = (rs1 == 0) ? 32'b0 : registers[rs1];
    assign read_data2 = (rs2 == 0) ? 32'b0 : registers[rs2];

    always @(posedge clk) begin
        if (rst) begin
            // During reset - clear all registers
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;
        end
        else if (reg_write && rd != 0) begin
            registers[rd] <= write_data;
        end
    end
endmodule