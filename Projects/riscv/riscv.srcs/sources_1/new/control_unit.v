// ============================================================
// MODULE 8 - PC
// FIX 1: removed pc_in port - uses own output reg directly
// FIX 2: added jalr port + rs1_data - JALR target = rs1+imm
//         JAL  target = pc+imm  (different!)
// ============================================================
module PC_n(
    input         clk, rst,
    input         branch, zero,
    input         jump,
    input         jalr,
    input  [31:0] imm,
    input  [31:0] rs1_data,
    output reg [31:0] pc
);

    wire [31:0] pc_plus4 = pc + 4;

    wire [31:0] pc_target =
        jalr ? ((rs1_data + imm) & 32'hFFFFFFFE)
              : (pc + imm);

    wire [31:0] next_pc =
        (jump || (branch && zero))
        ? pc_target
        : pc_plus4;

    always @(posedge clk or posedge rst) begin
        if (rst)
            pc <= 32'h0;
        else
            pc <= next_pc;
    end

endmodule