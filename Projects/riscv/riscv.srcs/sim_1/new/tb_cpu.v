`timescale 1ns / 1ps
// ============================================================
// SELF-CHECKING TESTBENCH FOR SINGLE-CYCLE RV32I CPU
// ============================================================
// Loads a hand-assembled RV32I program directly into the
// instruction memory (bypassing $readmemh / program.mem),
// runs the CPU until it hits a self-loop "halt" instruction,
// then checks register file + data memory contents against
// expected values.
//
// NOTE: The DUT's `im` module tries $readmemh("program.mem",...)
// at time 0. If that file doesn't exist in your sim directory,
// Vivado will print a benign warning ("failed to open ... ") --
// harmless, since this testbench overwrites the whole
// instruction memory anyway right after time 0.
// ============================================================

module tb_cpu;

    // ---------------- Clock / reset ----------------
    reg clk;
    reg rst;

    cpu uut (
        .clk (clk),
        .rst (rst)
    );

    always #5 clk = ~clk;   // 100 MHz-equivalent, 10ns period

    // ---------------- Opcodes ----------------
    localparam OP_R      = 7'b0110011;
    localparam OP_IALU   = 7'b0010011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;
    localparam OP_JAL    = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;

    // ---------------- Instruction encoders ----------------
    function [31:0] r_type(input [6:0] f7, input [4:0] rs2, input [4:0] rs1,
                            input [2:0] f3, input [4:0] rd, input [6:0] op);
        r_type = {f7, rs2, rs1, f3, rd, op};
    endfunction

    function [31:0] i_type(input [11:0] imm, input [4:0] rs1, input [2:0] f3,
                            input [4:0] rd, input [6:0] op);
        i_type = {imm, rs1, f3, rd, op};
    endfunction

    function [31:0] s_type(input [11:0] imm, input [4:0] rs2, input [4:0] rs1,
                            input [2:0] f3, input [6:0] op);
        s_type = {imm[11:5], rs2, rs1, f3, imm[4:0], op};
    endfunction

    function [31:0] b_type(input [12:0] imm, input [4:0] rs2, input [4:0] rs1,
                            input [2:0] f3, input [6:0] op);
        b_type = {imm[12], imm[10:5], rs2, rs1, f3, imm[4:1], imm[11], op};
    endfunction

    function [31:0] u_type(input [19:0] imm20, input [4:0] rd, input [6:0] op);
        u_type = {imm20, rd, op};
    endfunction

    function [31:0] j_type(input [20:0] imm, input [4:0] rd, input [6:0] op);
        j_type = {imm[20], imm[10:1], imm[11], imm[19:12], rd, op};
    endfunction

    // ---------------- Program layout (word indices) ----------------
    localparam IDX_ADDI_X1        = 0;
    localparam IDX_ADDI_X2        = 1;
    localparam IDX_ADD_X3         = 2;
    localparam IDX_SUB_X4         = 3;
    localparam IDX_AND_X5         = 4;
    localparam IDX_OR_X6          = 5;
    localparam IDX_XOR_X7         = 6;
    localparam IDX_SLT_X8         = 7;
    localparam IDX_SLT_X9         = 8;
    localparam IDX_ADDI_X10_NEG   = 9;
    localparam IDX_SLT_X29        = 10;
    localparam IDX_SLLI_X11       = 11;
    localparam IDX_SRLI_X12       = 12;
    localparam IDX_ANDI_X13       = 13;
    localparam IDX_ORI_X14        = 14;
    localparam IDX_XORI_X15       = 15;
    localparam IDX_SLTI_X16       = 16;
    localparam IDX_LUI_X17        = 17;
    localparam IDX_AUIPC_X18      = 18;
    localparam IDX_SW_X3_0        = 19;
    localparam IDX_LW_X19_0       = 20;
    localparam IDX_SW_X1_4        = 21;
    localparam IDX_LW_X20_4       = 22;
    localparam IDX_ADDI_X0_TEST   = 23;
    localparam IDX_BEQ_TAKEN      = 24;
    localparam IDX_SKIP_A         = 25;
    localparam IDX_SKIP_B         = 26;
    localparam IDX_TARGET1        = 27;
    localparam IDX_BEQ_NOTTAKEN   = 28;
    localparam IDX_AFTER_BEQ2     = 29;
    localparam IDX_JAL            = 30;
    localparam IDX_JAL_SKIP_A     = 31;
    localparam IDX_JAL_SKIP_B     = 32;
    localparam IDX_JAL_TARGET     = 33;
    localparam IDX_ADDI_X26_BASE  = 34;
    localparam IDX_JALR           = 35;
    localparam IDX_JALR_SKIP      = 36;
    localparam IDX_JALR_TARGET    = 37;
    localparam IDX_BNE_TEST       = 38;
    localparam IDX_BNE_FALLTHRU   = 39;
    localparam IDX_BNE_SKIP       = 40;
    localparam IDX_BNE_TARGET     = 41;
    localparam IDX_HALT           = 42;

    integer i;

    // ---------------- Pass/fail bookkeeping ----------------
    integer total_checks;
    integer total_pass;

    task check_reg(input [4:0] regnum, input [31:0] expected, input [639:0] name);
        begin
            total_checks = total_checks + 1;
            if (uut.reg_file.registers[regnum] === expected) begin
                total_pass = total_pass + 1;
                $display("PASS | %0s | x%0d = 0x%08h", name, regnum, uut.reg_file.registers[regnum]);
            end else begin
                $display("FAIL | %0s | x%0d = 0x%08h  (expected 0x%08h)", name, regnum, uut.reg_file.registers[regnum], expected);
            end
        end
    endtask

    task check_mem(input [7:0] word_idx, input [31:0] expected, input [639:0] name);
        begin
            total_checks = total_checks + 1;
            if (uut.data_mem.mem[word_idx] === expected) begin
                total_pass = total_pass + 1;
                $display("PASS | %0s | mem[%0d] = 0x%08h", name, word_idx, uut.data_mem.mem[word_idx]);
            end else begin
                $display("FAIL | %0s | mem[%0d] = 0x%08h  (expected 0x%08h)", name, word_idx, uut.data_mem.mem[word_idx], expected);
            end
        end
    endtask

    // ---------------- Stimulus ----------------
    initial begin
        clk = 0;
        rst = 1;
        total_checks = 0;
        total_pass   = 0;

        // Let the DUT's own instr_mem initial block (NOP-fill + failed
        // $readmemh) finish its time-0 activity first, then override.
        #1;

        // ---- R-type ALU ----
        uut.instr_mem.memory[IDX_ADDI_X1]      = i_type(12'd5,  5'd0, 3'b000, 5'd1,  OP_IALU);           // addi x1,x0,5
        uut.instr_mem.memory[IDX_ADDI_X2]      = i_type(12'd10, 5'd0, 3'b000, 5'd2,  OP_IALU);           // addi x2,x0,10
        uut.instr_mem.memory[IDX_ADD_X3]       = r_type(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, OP_R);     // add  x3,x1,x2
        uut.instr_mem.memory[IDX_SUB_X4]       = r_type(7'b0100000, 5'd1, 5'd2, 3'b000, 5'd4, OP_R);     // sub  x4,x2,x1
        uut.instr_mem.memory[IDX_AND_X5]       = r_type(7'b0000000, 5'd2, 5'd1, 3'b111, 5'd5, OP_R);     // and  x5,x1,x2
        uut.instr_mem.memory[IDX_OR_X6]        = r_type(7'b0000000, 5'd2, 5'd1, 3'b110, 5'd6, OP_R);     // or   x6,x1,x2
        uut.instr_mem.memory[IDX_XOR_X7]       = r_type(7'b0000000, 5'd2, 5'd1, 3'b100, 5'd7, OP_R);     // xor  x7,x1,x2
        uut.instr_mem.memory[IDX_SLT_X8]       = r_type(7'b0000000, 5'd2, 5'd1, 3'b010, 5'd8, OP_R);     // slt  x8,x1,x2 (5<10)
        uut.instr_mem.memory[IDX_SLT_X9]       = r_type(7'b0000000, 5'd1, 5'd2, 3'b010, 5'd9, OP_R);     // slt  x9,x2,x1 (10<5)

        // ---- Sign extension + signed compare ----
        uut.instr_mem.memory[IDX_ADDI_X10_NEG] = i_type(12'hFFF, 5'd0, 3'b000, 5'd10, OP_IALU);          // addi x10,x0,-1
        uut.instr_mem.memory[IDX_SLT_X29]      = r_type(7'b0000000, 5'd1, 5'd10, 3'b010, 5'd29, OP_R);   // slt x29,x10,x1 (-1<5)

        // ---- I-type ALU shifts (KNOWN BUG: alu_control has no
        //      funct3=001/101 entries for aluop=11, so these fall
        //      through to default ADD instead of shifting) ----
        uut.instr_mem.memory[IDX_SLLI_X11]     = i_type(12'd2, 5'd1, 3'b001, 5'd11, OP_IALU);            // slli x11,x1,2
        uut.instr_mem.memory[IDX_SRLI_X12]     = i_type(12'd1, 5'd2, 3'b101, 5'd12, OP_IALU);            // srli x12,x2,1

        // ---- Remaining I-type ALU ----
        uut.instr_mem.memory[IDX_ANDI_X13]     = i_type(12'd3,  5'd1, 3'b111, 5'd13, OP_IALU);           // andi x13,x1,3
        uut.instr_mem.memory[IDX_ORI_X14]      = i_type(12'd2,  5'd1, 3'b110, 5'd14, OP_IALU);           // ori  x14,x1,2
        uut.instr_mem.memory[IDX_XORI_X15]     = i_type(12'd1,  5'd1, 3'b100, 5'd15, OP_IALU);           // xori x15,x1,1
        uut.instr_mem.memory[IDX_SLTI_X16]     = i_type(12'd10, 5'd1, 3'b010, 5'd16, OP_IALU);           // slti x16,x1,10

        // ---- U-type ----
        uut.instr_mem.memory[IDX_LUI_X17]      = u_type(20'h12345, 5'd17, OP_LUI);                       // lui   x17,0x12345
        uut.instr_mem.memory[IDX_AUIPC_X18]    = u_type(20'd1,     5'd18, OP_AUIPC);                     // auipc x18,1

        // ---- Loads / stores ----
        uut.instr_mem.memory[IDX_SW_X3_0]      = s_type(12'd0, 5'd3,  5'd0, 3'b010, OP_STORE);           // sw x3,0(x0)
        uut.instr_mem.memory[IDX_LW_X19_0]     = i_type(12'd0, 5'd0,  3'b010, 5'd19, OP_LOAD);           // lw x19,0(x0)
        uut.instr_mem.memory[IDX_SW_X1_4]      = s_type(12'd4, 5'd1,  5'd0, 3'b010, OP_STORE);           // sw x1,4(x0)
        uut.instr_mem.memory[IDX_LW_X20_4]     = i_type(12'd4, 5'd0,  3'b010, 5'd20, OP_LOAD);           // lw x20,4(x0)

        // ---- x0 write-protect ----
        uut.instr_mem.memory[IDX_ADDI_X0_TEST] = i_type(12'd123, 5'd0, 3'b000, 5'd0, OP_IALU);           // addi x0,x0,123

        // ---- beq taken ----
        uut.instr_mem.memory[IDX_BEQ_TAKEN]    = b_type((IDX_TARGET1 - IDX_BEQ_TAKEN) * 4, 5'd1, 5'd1, 3'b000, OP_BRANCH); // beq x1,x1,TARGET1
        uut.instr_mem.memory[IDX_SKIP_A]       = i_type(12'd999, 5'd0, 3'b000, 5'd21, OP_IALU);          // addi x21,x0,999 (skipped)
        uut.instr_mem.memory[IDX_SKIP_B]       = i_type(12'd888, 5'd0, 3'b000, 5'd21, OP_IALU);          // addi x21,x0,888 (skipped)
        uut.instr_mem.memory[IDX_TARGET1]      = i_type(12'd111, 5'd0, 3'b000, 5'd21, OP_IALU);          // addi x21,x0,111 (target)

        // ---- beq not taken ----
        uut.instr_mem.memory[IDX_BEQ_NOTTAKEN] = b_type((IDX_TARGET1 - IDX_BEQ_NOTTAKEN) * 4, 5'd2, 5'd1, 3'b000, OP_BRANCH); // beq x1,x2,(unused target)
        uut.instr_mem.memory[IDX_AFTER_BEQ2]   = i_type(12'd55, 5'd0, 3'b000, 5'd22, OP_IALU);           // addi x22,x0,55

        // ---- jal ----
        uut.instr_mem.memory[IDX_JAL]          = j_type((IDX_JAL_TARGET - IDX_JAL) * 4, 5'd23, OP_JAL);  // jal x23,JAL_TARGET
        uut.instr_mem.memory[IDX_JAL_SKIP_A]   = i_type(12'd999, 5'd0, 3'b000, 5'd24, OP_IALU);          // (skipped)
        uut.instr_mem.memory[IDX_JAL_SKIP_B]   = i_type(12'd888, 5'd0, 3'b000, 5'd24, OP_IALU);          // (skipped)
        uut.instr_mem.memory[IDX_JAL_TARGET]   = i_type(12'd222, 5'd0, 3'b000, 5'd24, OP_IALU);          // addi x24,x0,222 (target)

        // ---- jalr ----
        uut.instr_mem.memory[IDX_ADDI_X26_BASE]= i_type(IDX_JALR_TARGET * 4, 5'd0, 3'b000, 5'd26, OP_IALU); // addi x26,x0,<target addr>
        uut.instr_mem.memory[IDX_JALR]         = i_type(12'd0, 5'd26, 3'b000, 5'd25, OP_JALR);           // jalr x25,0(x26)
        uut.instr_mem.memory[IDX_JALR_SKIP]    = i_type(12'd999, 5'd0, 3'b000, 5'd27, OP_IALU);          // (skipped)
        uut.instr_mem.memory[IDX_JALR_TARGET]  = i_type(12'd333, 5'd0, 3'b000, 5'd27, OP_IALU);          // addi x27,x0,333 (target)

        // ---- bne (KNOWN BUG: alu_control forces SUB for ANY branch
        //      opcode regardless of funct3, and CU never looks at
        //      funct3 either, so bne behaves like beq -- it will NOT
        //      branch here even though x1 != x2, which is wrong) ----
        uut.instr_mem.memory[IDX_BNE_TEST]     = b_type((IDX_BNE_TARGET - IDX_BNE_TEST) * 4, 5'd2, 5'd1, 3'b001, OP_BRANCH); // bne x1,x2,TARGET
        uut.instr_mem.memory[IDX_BNE_FALLTHRU] = i_type(12'd1, 5'd0, 3'b000, 5'd28, OP_IALU);            // addi x28,x0,1 (reached only if NOT taken)
        uut.instr_mem.memory[IDX_BNE_SKIP]     = j_type((IDX_HALT - IDX_BNE_SKIP) * 4, 5'd0, OP_JAL);    // jal x0,HALT (skip over TARGET so paths don't merge)
        uut.instr_mem.memory[IDX_BNE_TARGET]   = i_type(12'd2, 5'd0, 3'b000, 5'd28, OP_IALU);            // addi x28,x0,2 (reached only if branch correctly taken)

        // ---- halt (self-loop) ----
        uut.instr_mem.memory[IDX_HALT]         = j_type(21'd0, 5'd0, OP_JAL);                            // jal x0,0  (spin here forever)

        // ---- Release reset ----
        @(negedge clk);
        @(negedge clk);
        rst = 0;

        // ---- Run until PC reaches the halt instruction, or timeout ----
        i = 0;
        while (uut.pc !== (IDX_HALT * 4) && i < 500) begin
            @(negedge clk);
            i = i + 1;
        end

        if (uut.pc !== (IDX_HALT * 4)) begin
            $display("TIMEOUT: PC never reached halt address. Stuck at PC=0x%08h", uut.pc);
        end else begin
            $display("Reached halt loop at PC=0x%08h after %0d cycles.", uut.pc, i);
        end

        $display("");
        $display("========== REGISTER / MEMORY CHECKS ==========");

        check_reg(1,  32'd5,          "addi x1,x0,5");
        check_reg(2,  32'd10,         "addi x2,x0,10");
        check_reg(3,  32'd15,         "add  x3,x1,x2");
        check_reg(4,  32'd5,          "sub  x4,x2,x1");
        check_reg(5,  32'd0,          "and  x5,x1,x2");
        check_reg(6,  32'd15,         "or   x6,x1,x2");
        check_reg(7,  32'd15,         "xor  x7,x1,x2");
        check_reg(8,  32'd1,          "slt  x8,x1,x2 (5<10)");
        check_reg(9,  32'd0,          "slt  x9,x2,x1 (10<5)");
        check_reg(10, 32'hFFFFFFFF,   "addi x10,x0,-1 (sign extend)");
        check_reg(29, 32'd1,          "slt  x29,x10,x1 (-1<5 signed)");
        check_reg(11, 32'd20,         "slli x11,x1,2  [KNOWN BUG if FAIL: shifts unimplemented for I-type]");
        check_reg(12, 32'd5,          "srli x12,x2,1  [KNOWN BUG if FAIL: shifts unimplemented for I-type]");
        check_reg(13, 32'd1,          "andi x13,x1,3");
        check_reg(14, 32'd7,          "ori  x14,x1,2");
        check_reg(15, 32'd4,          "xori x15,x1,1");
        check_reg(16, 32'd1,          "slti x16,x1,10");
        check_reg(17, 32'h12345000,   "lui  x17,0x12345");
        check_reg(18, (IDX_AUIPC_X18*4) + 32'h1000, "auipc x18,1");
        check_reg(0,  32'd0,          "addi x0,x0,123 (x0 must stay 0)");
        check_reg(21, 32'd111,        "beq taken -> correct target reached");
        check_reg(22, 32'd55,         "beq not-taken -> fallthrough reached");
        check_reg(23, (IDX_JAL*4)+4,  "jal x23,target -> link addr = pc+4");
        check_reg(24, 32'd222,        "jal -> correct target reached");
        check_reg(26, IDX_JALR_TARGET*4, "addi x26,x0,<target addr>");
        check_reg(25, (IDX_JALR*4)+4, "jalr x25,0(x26) -> link addr = pc+4");
        check_reg(27, 32'd333,        "jalr -> target = rs1+imm reached correctly");
        check_reg(28, 32'd2,          "bne x1,x2 should branch (x1!=x2) [KNOWN BUG if FAIL: branch funct3 ignored]");

        check_mem(0, 32'd15, "sw x3,0(x0) -> mem[0]");
        check_mem(1, 32'd5,  "sw x1,4(x0) -> mem[1]");
        check_reg(19, 32'd15, "lw x19,0(x0)");
        check_reg(20, 32'd5,  "lw x20,4(x0)");

        $display("");
        $display("========== SUMMARY ==========");
        $display("Total checks: %0d", total_checks);
        $display("Passed:       %0d", total_pass);
        $display("Failed:       %0d", total_checks - total_pass);
        $display("==============================");

        $finish;
    end

endmodule