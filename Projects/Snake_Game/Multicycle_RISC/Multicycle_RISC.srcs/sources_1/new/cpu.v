// ============================================================
// Multi-cycle RV32I CPU
// Reuses: alu, alu_control, CU, ImmGen, Reg_file, im, DataMem
//
// States:  FETCH -> DECODE -> EXEC -> [MEM] -> [WB] -> FETCH
//   FETCH : IR <= inst_mem[pc]
//   DECODE: A <= rs1, B <= rs2
//   EXEC  : ALU op / address calc / branch + jump PC update
//   MEM   : load (MDR <= mem) or store (mem <= B)
//   WB    : regfile <= result ; PC <= PC+4 (non-branch/jump)
//
// Memory-mapped I/O (addresses 0x4xxx_xxxx):
//   0x40000000 write : send low 8 bits of the word over UART
//   0x40000004 read  : bit 0 = UART tx busy
//   0x40000008 read  : bit 8 = rx valid, bits [7:0] = received char
//                      (reading clears rx valid)
//   0x4000000C read  : bits [3:0] = {btnU, btnD, btnL, btnR}
// ============================================================
module cpu(
    input         clk,
    input         rst,
    input  [4:0]  dbg_reg_sel,
    output [31:0] dbg_reg_data,
    output [31:0] dbg_pc,
    // UART transmitter
    output [7:0]  uart_wdata,
    output        uart_wr,
    input         uart_busy,
    // UART receiver
    input  [7:0]  rx_data,
    input         rx_valid,
    output        rx_ack,
    // direction buttons {up, down, left, right}
    input  [3:0]  btn
);
    localparam S_FETCH  = 3'd0,
               S_DECODE = 3'd1,
               S_EXEC   = 3'd2,
               S_MEM    = 3'd3,
               S_WB     = 3'd4;

    reg  [2:0]  state;
    reg  [31:0] pc;
    reg  [31:0] IR, A, B, ALUOut, MDR;

    wire [31:0] inst;           // raw instruction memory output
    wire [31:0] imm, rs1_data, rs2_data, mem_rdata, dm_rdata;
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

    // ---------------- memory-mapped I/O ----------------
    wire io_sel = (ALUOut[31:28] == 4'h4);

    wire [31:0] io_rdata =
        (ALUOut == 32'h40000004) ? {31'b0, uart_busy}         :
        (ALUOut == 32'h40000008) ? {23'b0, rx_valid, rx_data} :
        (ALUOut == 32'h4000000C) ? {28'b0, btn}               :
                                   32'b0;

    assign mem_rdata = io_sel ? io_rdata : dm_rdata;

    // one-cycle pulse (state S_MEM lasts exactly one clock)
    assign rx_ack = MemRead & (ALUOut == 32'h40000008);

    assign uart_wr    = MemWrite & (ALUOut == 32'h40000000);
    assign uart_wdata = B[7:0];

    // ---------------- datapath ----------------
    wire [31:0] pc_plus4  = pc + 32'd4;
    wire [31:0] pc_target = jalr ? ((A + imm) & 32'hFFFFFFFE) : (pc + imm);

    // branch condition (funct3 = IR[14:12]): beq bne blt bge bltu bgeu
    wire eq  = (A == B);
    wire lt  = ($signed(A) < $signed(B));
    wire ltu = (A < B);
    reg  cond;
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
    wire branch_taken = Branch & cond;

    assign alu_input_A = ALUSrcA ? pc  : A;
    assign alu_input_B = ALUSrc  ? imm : B;

    // value to latch into ALUOut at end of EXEC
    wire [31:0] exec_result =
        (ResultSrc == 2'b10) ? pc_plus4 :   // JAL / JALR link
        (ResultSrc == 2'b11) ? imm      :   // LUI
                               alu_result;  // everything else

    wire [31:0] write_back = (ResultSrc == 2'b01) ? MDR : ALUOut;

    // ---------------- PC update ----------------
    wire pc_we =
        (state == S_EXEC && (Jump || Branch)) ||
        (state == S_MEM  && MemWrite_c)       ||
        (state == S_WB   && !Jump && !Branch);

    wire [31:0] pc_next =
        (state == S_EXEC && Jump)                   ? pc_target :
        (state == S_EXEC && Branch && branch_taken) ? pc_target :
                                                      pc_plus4;

    always @(posedge clk or posedge rst) begin
        if (rst)
            pc <= 32'h0;
        else if (pc_we)
            pc <= pc_next;
    end

    // ---------------- pipeline-style registers ----------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            IR <= 32'h00000013; A <= 0; B <= 0; ALUOut <= 0; MDR <= 0;
        end else begin
            if (state == S_FETCH)  IR <= inst;
            if (state == S_DECODE) begin A <= rs1_data; B <= rs2_data; end
            if (state == S_EXEC)   ALUOut <= exec_result;
            if (state == S_MEM)    MDR <= mem_rdata;
        end
    end

    // ---------------- FSM ----------------
    always @(posedge clk or posedge rst) begin
        if (rst) state <= S_FETCH;
        else case (state)
            S_FETCH : state <= S_DECODE;
            S_DECODE: state <= S_EXEC;
            S_EXEC  : state <= Branch                    ? S_FETCH :
                               (MemRead_c || MemWrite_c) ? S_MEM   : S_WB;
            S_MEM   : state <= MemWrite_c ? S_FETCH : S_WB;
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
        .clk(clk), .MemWrite(MemWrite & ~io_sel), .MemRead(MemRead & ~io_sel),
        .funct3(IR[14:12]),       // access size: byte / half / word
        .addr(ALUOut),            // registered address from EXEC
        .write_data(B),           // registered rs2
        .read_data(dm_rdata)
    );
endmodule