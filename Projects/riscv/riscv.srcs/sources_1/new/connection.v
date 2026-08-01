// ============================================================
// MODULE 9 - TOP MODULE (cpu)
// FIX 1: pc_plus4_reg is a registered signal - captures pc+4
//         BEFORE pc updates, so JAL/JALR get correct return addr
//Fix 1.1 : LUI 
// FIX 2: alu_input_A MUX - ALUSrcA selects PC for AUIPC
// FIX 3: all new ports wired (ALUSrcA, jalr, rs1_data to PC_n)
// ============================================================
module cpu(
    input clk,
    input rst
);
 
// ── Wire declarations ─────────────────────────────────────────────
    wire [31:0] pc;
    wire [31:0] inst;
 
    // Control signals
    wire        RegWrite;
    wire        ALUSrcA;        // FIX: new - selects ALU input A
    wire        ALUSrc;
    wire        MemRead, MemWrite;
    wire [1:0]  ResultSrc;
    wire        Branch, Jump;
    wire        jalr;           // FIX: new - distinguishes JALR from JAL
    wire [1:0]  ALUOp;
 
    // Datapath wires
    wire [31:0] imm;
    wire [31:0] rs1_data, rs2_data;
    wire [31:0] write_back;
    wire [3:0]  alu_ctrl;
    wire [31:0] alu_input_A;    // FIX: new - rs1 or PC
    wire [31:0] alu_input_B;    // rs2 or imm
    wire [31:0] alu_result;
    wire        zero;
    wire [31:0] mem_rdata;
 
    wire [31:0] pc_plus4;
    assign pc_plus4 = pc + 4;
 
    // ALUSrc MUXes
    assign alu_input_A = ALUSrcA ? pc : rs1_data;  // FIX: PC for AUIPC
    assign alu_input_B = ALUSrc  ? imm : rs2_data;
 
// ── PC ───────────────────────────────────────────────────────────
    // FIX: no .pc_in port, added .jalr and .rs1_data
    PC_n pc_reg (
        .clk      (clk),
        .rst      (rst),
        .branch   (Branch),
        .zero     (zero),
        .jump     (Jump),
        .jalr     (jalr),           // FIX: new
        .imm      (imm),
        .rs1_data (rs1_data),       // FIX: new - for JALR target
        .pc       (pc)
    );
 
// ── Instruction Memory ────────────────────────────────────────────
    im instr_mem (
        .pc   (pc),
        .inst (inst)
    );
 
// ── Control Unit ──────────────────────────────────────────────────
    CU control_unit (
        .opcode    (inst[6:0]),
        .RegWrite  (RegWrite),
        .ALUSrcA   (ALUSrcA),       // FIX: new
        .ALUSrc    (ALUSrc),
        .MemRead   (MemRead),
        .MemWrite  (MemWrite),
        .ResultSrc (ResultSrc),
        .Branch    (Branch),
        .Jump      (Jump),
        .jalr      (jalr),          // FIX: new
        .ALUOp     (ALUOp)
    );
 
// ── ImmGen ────────────────────────────────────────────────────────
    ImmGen immgen (
        .inst (inst),
        .imm  (imm)
    );
 
// ── Register File ─────────────────────────────────────────────────
    // FIX: .rst connected
    Reg_file reg_file (
        .clk        (clk),
        .rst        (rst),          // FIX: gates writes during reset
        .reg_write  (RegWrite),
        .rs1        (inst[19:15]),
        .rs2        (inst[24:20]),
        .rd         (inst[11:7]),
        .write_data (write_back),
        .read_data1 (rs1_data),
        .read_data2 (rs2_data)
    );
 
// ── ALU Control ───────────────────────────────────────────────────
    alu_control alu_ctrl_unit (
        .aluop (ALUOp),
        .f3    (inst[14:12]),
        .f7    (inst[30]),          // funct7[5]
        .alu_c (alu_ctrl)
    );
 
// ── ALU ───────────────────────────────────────────────────────────
    // FIX: A is now alu_input_A (rs1 or PC), not always rs1_data
    alu main_alu (
        .A        (alu_input_A),    // FIX: was rs1_data
        .B        (alu_input_B),
        .alu_ctrl (alu_ctrl),
        .Y        (alu_result),
        .zero     (zero)
    );
 
// ── Data Memory ───────────────────────────────────────────────────
    DataMem data_mem (
        .clk        (clk),
        .MemWrite   (MemWrite),
        .MemRead    (MemRead),
        .addr       (alu_result),   // address = rs1+imm from ALU
        .write_data (rs2_data),     // data = rs2 value (NOT alu_result)
        .read_data  (mem_rdata)
    );
 
// ── Write-Back MUX ────────────────────────────────────────────────
    // FIX: ResultSrc=10 now uses pc_plus4_reg (registered capture)
    //      not a combinational pc+4 which sees updated PC
    // NEW
assign write_back =
    (ResultSrc == 2'b01) ? mem_rdata    :  // LOAD
    (ResultSrc == 2'b10) ? pc_plus4 :  // JAL/JALR
    (ResultSrc == 2'b11) ? imm          :  // LUI - direct from ImmGen
                           alu_result   ;  // R-type, I-ALU, AUIPC, STORE(unused)
endmodule
