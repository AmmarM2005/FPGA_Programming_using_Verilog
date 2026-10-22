// ============================================================
// Multi-cycle RV32I CPU  (drop-in replacement for connection.v)
// Same ports as the single-cycle "cpu" module.
// Reuses: alu, alu_control, CU, ImmGen, Reg_file, im, DataMem
// Do NOT include PC.v or control_unit.v (old PC_n) any more.
//
// States:  FETCH -> DECODE -> EXEC -> [MEM] -> [WB] -> FETCH
//   FETCH : IR <= inst_mem[pc]
//   DECODE: A <= rs1, B <= rs2
//   EXEC  : ALU op / address calc / branch + jump PC update
//   MEM   : load (MDR <= mem) or store (mem <= B)
//   WB    : regfile <= result ; PC <= PC+4 (non-branch/jump)
//   MUL   : (mul only) EXEC -> MUL x32 -> WB, shift-add multiplier
// ============================================================
module cpu(
    input         clk,
    input         rst,
    input  [4:0]  dbg_reg_sel,
    output [31:0] dbg_reg_data,
    output [31:0] dbg_pc
);
    localparam S_FETCH  = 3'd0,
               S_DECODE = 3'd1,
               S_EXEC   = 3'd2,
               S_MEM    = 3'd3,
               S_WB     = 3'd4,
               S_MUL    = 3'd5;   // NEW: multiply iterations

    reg  [2:0]  state;
    reg  [31:0] pc;
    reg  [31:0] IR, A, B, ALUOut, MDR;

    // ---------------- NEW: shift-add multiplier registers ----------------
    reg  [31:0] mcand;      // multiplicand, shifts left each cycle
    reg  [31:0] mplier;     // multiplier, shifts right each cycle
    reg  [31:0] prod;       // running product (low 32 bits)
    reg  [4:0]  mcnt;       // iteration counter 0..31
    wire [31:0] prod_next = prod + (mplier[0] ? mcand : 32'd0);
    // mul = R-type opcode, funct7 = 0000001, funct3 = 000
    wire        is_mul = (IR[6:0] == 7'b0110011) &&
                         (IR[31:25] == 7'b0000001) &&
                         (IR[14:12] == 3'b000);

    wire [31:0] inst;           // raw instruction memory output
    wire [31:0] imm, rs1_data, rs2_data, mem_rdata;
    wire [31:0] alu_input_A, alu_input_B, alu_result;
    wire [3:0]  alu_ctrl;
    wire        zero;

    // raw control (decoded from IR, which is a register -> stable)
    wire RegWrite_c, ALUSrcA, ALUSrc, MemRead_c, MemWrite_c;
    wire Branch, Jump, jalr;
    wire [1:0] ResultSrc, ALUOp;

    assign dbg_pc = pc;

    // ---------------- state-gated control ----------------
    wire RegWrite = RegWrite_c & (state == S_WB);
    wire MemWrite = MemWrite_c & (state == S_MEM);
    wire MemRead  = MemRead_c  & (state == S_MEM);

    // ---------------- datapath ----------------
    wire [31:0] pc_plus4  = pc + 32'd4;
    wire [31:0] pc_target = jalr ? ((A + imm) & 32'hFFFFFFFE) : (pc + imm);
    // branch condition (funct3 = IR[14:12]): beq bne blt bge bltu bgeu
    wire        eq  = (A == B);
    wire        lt  = ($signed(A) < $signed(B));
    wire        ltu = (A < B);
    reg         cond;
    always @(*) begin
        case (IR[14:12])
            3'b000:  cond = eq;       // beq
            3'b001:  cond = ~eq;      // bne
            3'b100:  cond = lt;       // blt
            3'b101:  cond = ~lt;      // bge
            3'b110:  cond = ltu;      // bltu
            3'b111:  cond = ~ltu;     // bgeu
            default: cond = 1'b0;
        endcase
    end
    wire        branch_taken = Branch & cond;

    assign alu_input_A = ALUSrcA ? pc  : A;
    assign alu_input_B = ALUSrc  ? imm : B;

    // value to latch into ALUOut at end of EXEC
    wire [31:0] exec_result =
        (ResultSrc == 2'b10) ? pc_plus4 :   // JAL / JALR link
        (ResultSrc == 2'b11) ? imm      :   // LUI
                               alu_result;  // everything else

    wire [31:0] write_back = (ResultSrc == 2'b01) ? MDR : ALUOut;

    // ---------------- PC update ----------------
    wire pc_we = (state == S_EXEC && (Branch || Jump)) ||
                 (state == S_MEM  && MemWrite_c)      ||   // store
                 (state == S_WB   && !Jump);
    wire [31:0] pc_next =
        (state == S_EXEC && (Jump || branch_taken)) ? pc_target : pc_plus4;

    always @(posedge clk or posedge rst) begin
        if (rst) pc <= 32'h0;
        else if (pc_we) pc <= pc_next;
    end

    // ---------------- pipeline-style registers ----------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            IR <= 32'h00000013; A <= 0; B <= 0; ALUOut <= 0; MDR <= 0;
            mcand <= 0; mplier <= 0; prod <= 0; mcnt <= 0;
        end else begin
            if (state == S_FETCH)  IR <= inst;
            if (state == S_DECODE) begin A <= rs1_data; B <= rs2_data; end
            if (state == S_EXEC)   begin
                ALUOut <= exec_result;
                // NEW: start the multiplier
                mcand <= A; mplier <= B; prod <= 0; mcnt <= 0;
            end
            if (state == S_MEM)    MDR <= mem_rdata;
            // NEW: one shift-add step per clock
            if (state == S_MUL) begin
                prod   <= prod_next;
                mcand  <= mcand << 1;
                mplier <= mplier >> 1;
                mcnt   <= mcnt + 5'd1;
                if (mcnt == 5'd31) ALUOut <= prod_next;   // final result
            end
        end
    end

    // ---------------- FSM ----------------
    always @(posedge clk or posedge rst) begin
        if (rst) state <= S_FETCH;
        else case (state)
            S_FETCH : state <= S_DECODE;
            S_DECODE: state <= S_EXEC;
            S_EXEC  : state <= Branch                    ? S_FETCH :
                               is_mul                    ? S_MUL   :   // NEW
                               (MemRead_c || MemWrite_c) ? S_MEM   : S_WB;
            S_MEM   : state <= MemWrite_c ? S_FETCH : S_WB;
            S_MUL   : state <= (mcnt == 5'd31) ? S_WB : S_MUL;         // NEW
            S_WB    : state <= S_FETCH;
            default : state <= S_FETCH;
        endcase
    end

    // ---------------- submodules ----------------
    im instr_mem (.pc(pc), .inst(inst));

    CU control_unit (
        .opcode(IR[6:0]),
        .RegWrite(RegWrite_c), .ALUSrcA(ALUSrcA), .ALUSrc(ALUSrc),
        .MemRead(MemRead_c),   .MemWrite(MemWrite_c),
        .ResultSrc(ResultSrc), .Branch(Branch), .Jump(Jump),
        .jalr(jalr),           .ALUOp(ALUOp)
    );

    ImmGen immgen (.inst(IR), .imm(imm));

    Reg_file reg_file (
        .clk(clk), .rst(rst), .reg_write(RegWrite),
        .rs1(IR[19:15]), .rs2(IR[24:20]), .rd(IR[11:7]),
        .write_data(write_back),
        .read_data1(rs1_data), .read_data2(rs2_data),
        .dbg_sel(dbg_reg_sel), .dbg_data(dbg_reg_data)
    );

    alu_control alu_ctrl_unit (
        .aluop(ALUOp), .f3(IR[14:12]), .f7(IR[30]), .alu_c(alu_ctrl)
    );

    alu main_alu (
        .A(alu_input_A), .B(alu_input_B),
        .alu_ctrl(alu_ctrl), .Y(alu_result), .zero(zero)
    );

    DataMem data_mem (
        .clk(clk), .MemWrite(MemWrite), .MemRead(MemRead),
        .funct3(IR[14:12]),       // access size: byte / half / word
        .addr(ALUOut),            // registered address from EXEC
        .write_data(B),           // registered rs2
        .read_data(mem_rdata)
    );
endmodule