`timescale 1ns/1ps
// ============================================================
// Self-checking testbench for the multi-cycle RV32I CPU.
// Tests the NEW instructions with the new program.mem:
//   sltu sltiu  blt bge bltu bgeu  sb sh lb lbu lh lhu
// (sw lw addi lui slt are used as helpers and checked too.)
//
// How it works:
//   1. Holds reset for 3 clocks, then releases it.
//   2. The CPU runs program.mem until the PC reaches the final
//      "jal x0,0" halt loop at 0xB0 (or a 3000-cycle timeout).
//   3. Runs 20 more clocks to prove the CPU stays in the halt loop.
//   4. Each check loads the t_* variables; one $monitor prints
//      a PASS/FAIL line for every check.
// ============================================================
module tb_cpu;
    // ---------------- signals ----------------
    reg         clk = 0;          // CPU clock
    reg         rst = 1;          // reset, starts asserted
    reg  [4:0]  sel = 0;          // register number shown on dbg_reg_data
    wire [31:0] rdata;            // value of register 'sel'
    wire [31:0] pc;               // current program counter
    integer     errors = 0;       // number of failed checks
    integer     cycles = 0;       // clocks spent waiting for the halt loop

    // signals watched by $monitor
    reg [95:0]  t_name = "";
    integer     t_idx  = 0;
    reg [31:0]  t_got  = 0;
    reg [31:0]  t_exp  = 0;
    reg         t_pass = 0;
    integer     t_num  = 0;
    wire [31:0] t_res  = t_pass ? "PASS" : "FAIL";   // text shown by $monitor

    // address of the last instruction in program.mem (new program): "jal x0,0" (halt)
    localparam HALT_PC = 32'h0000_00B0;

    // ---------------- device under test ----------------
    cpu dut (
        .clk          (clk),
        .rst          (rst),
        .dbg_reg_sel  (sel),
        .dbg_reg_data (rdata),
        .dbg_pc       (pc)
    );

    // 100 MHz clock: toggles every 5 ns
    always #5 clk = ~clk;

    // ---------------- check helpers ----------------
    // common step: record result so $monitor prints it
    task do_check(input [95:0] name, input integer idx,
                  input [31:0] got, input [31:0] expected);
        begin
            t_name = name;  t_idx = idx;
            t_got  = got;   t_exp = expected;
            t_pass = (got === expected);
            if (!t_pass) errors = errors + 1;
            t_num = t_num + 1;                 // triggers $monitor
            #1;                                // let $monitor print
        end
    endtask

    // Select register 'r' on the debug port and compare with 'expected'.
    task check_reg(input [4:0] r, input [31:0] expected, input [95:0] name);
        begin
            sel = r; #1;                       // let the debug mux settle
            do_check(name, r, rdata, expected);
        end
    endtask

    // Compare data-memory word 'idx' (byte address idx*4) with 'expected'.
    task check_mem(input integer idx, input [31:0] expected, input [95:0] name);
        begin
            do_check(name, idx, dut.data_mem.mem[idx], expected);
        end
    endtask

    // ---------------- main test sequence ----------------
    initial begin
        $dumpfile("tb_cpu.vcd");
        $dumpvars(0, tb_cpu);

        // release reset after 3 clocks
        repeat (3) @(posedge clk);
        rst = 0;

        // run until the CPU reaches the halt loop (or time out)
        while (pc !== HALT_PC && cycles < 3000) begin
            @(posedge clk);
            cycles = cycles + 1;
        end
        repeat (20) @(posedge clk);            // must stay in the halt loop
        #1;

        $display("---- finished after %0d cycles, PC = %h (expect %h) ----",
                 cycles, pc, HALT_PC);

        $monitor("%s  %-12s idx=%0d got=%h exp=%h",
                 t_res, t_name, t_idx, t_got, t_exp);

        // PC must have settled on the halt loop
        do_check("PC halt", 0, pc, HALT_PC);

        // ======================================================
        // Setup and unsigned compare  (x1 = -1, x2 = 1)
        // ======================================================
        check_reg(1,  32'hFFFFFFFF, "addi");      // addi x1,x0,-1     -> -1 (0xFFFFFFFF)
        check_reg(2,  32'h00000001, "addi");      // addi x2,x0,1      -> 1
        check_reg(3,  32'h00000000, "sltu f");    // sltu x3,x1,x2     -> 0xFFFFFFFF < 1 unsigned = 0
        check_reg(4,  32'h00000001, "sltu t");    // sltu x4,x2,x1     -> 1 < 0xFFFFFFFF unsigned = 1
        check_reg(5,  32'h00000001, "slt");       // slt  x5,x1,x2     -> -1 < 1 signed = 1 (differs from sltu)
        check_reg(6,  32'h00000001, "sltiu t");   // sltiu x6,x2,-1    -> 1 < 0xFFFFFFFF unsigned = 1
        check_reg(7,  32'h00000000, "sltiu f");   // sltiu x7,x1,1     -> 0xFFFFFFFF < 1 unsigned = 0

        // ======================================================
        // Branches: blt / bge / bltu / bgeu
        // ======================================================
        // x10..x14 are only written by instructions that SHOULD be skipped
        // (one per TAKEN branch), so all must still be 0.
        check_reg(10, 32'h00000000, "blt taken");   // blt  x1,x2   (-1 < 1)
        check_reg(11, 32'h00000000, "bge taken");   // bge  x2,x1   (1 >= -1)
        check_reg(12, 32'h00000000, "bltu taken");  // bltu x2,x1   (1 < 0xFFFFFFFF)
        check_reg(13, 32'h00000000, "bgeu taken");  // bgeu x1,x2   (0xFFFFFFFF >= 1)
        check_reg(14, 32'h00000000, "bge equal");   // bge  x1,x1   (equal -> taken)
        // x15..x18 are written by the fall-through after a NOT-taken branch -> 1.
        check_reg(15, 32'h00000001, "blt not");     // blt  x2,x1   (1 < -1 false)
        check_reg(16, 32'h00000001, "bge not");     // bge  x1,x2   (-1 >= 1 false)
        check_reg(17, 32'h00000001, "bltu not");    // bltu x1,x2   (0xFFFFFFFF < 1 false)
        check_reg(18, 32'h00000001, "bgeu not");    // bgeu x2,x1   (1 >= 0xFFFFFFFF false)

        // ======================================================
        // Memory: sb / sh / lb / lbu / lh / lhu
        // ======================================================
        check_reg(8,  32'h12345678, "lui+addi");  // lui x8,0x12345 ; addi x8,x8,0x678
        check_reg(9,  32'h00000080, "addi");      // addi x9,x0,0x80
        check_reg(19, 32'hFFFFFF80, "lb neg");    // lb   x19,5(x0)    -> byte 0x80 sign-extended
        check_reg(20, 32'h00000080, "lbu");       // lbu  x20,5(x0)    -> byte 0x80 zero-extended
        check_reg(21, 32'h00000078, "lb 0");      // lb   x21,0(x0)    -> byte 0 of 0x12345678 = 0x78
        check_reg(22, 32'h00000012, "lb 3");      // lb   x22,3(x0)    -> byte 3 of 0x12345678 = 0x12
        check_reg(23, 32'h00001234, "lh");        // lh   x23,2(x0)    -> upper half 0x1234
        check_reg(24, 32'h00001234, "lhu");       // lhu  x24,2(x0)    -> upper half 0x1234
        check_reg(25, 32'hFFFFFFFE, "addi neg");  // addi x25,x0,-2
        check_reg(26, 32'hFFFFFFFE, "lh neg");    // lh   x26,10(x0)   -> half 0xFFFE sign-extended
        check_reg(27, 32'h0000FFFE, "lhu");       // lhu  x27,10(x0)   -> half 0xFFFE zero-extended
        check_reg(28, 32'h00000078, "sw intact"); // lb   x28,0(x0)    -> word 0 not damaged by later sb/sh
        check_reg(29, 32'h78808000, "sb bytes");  // lw   x29,4(x0)    -> sb at +5,+6,+7 -> 0x78808000
        check_mem(0,  32'h12345678, "sw");        // sw x8,0(x0)       -> mem[0]
        check_mem(1,  32'h78808000, "sb");        // sb x9,5 ; sb x9,6 ; sb x8,7 -> only those bytes change
        check_mem(2,  32'hFFFE0000, "sh");        // sh x25,10(x0)     -> upper half of mem[2] only

        // ---- summary ----
        $monitoroff;
        if (errors == 0) $display("\n*** ALL TESTS PASSED ***");
        else             $display("\n*** %0d TEST(S) FAILED ***", errors);
        $finish;
    end
endmodule