//=====================================================
// Design: 2-input AND Gate
//=====================================================
module and_gate(
    input  a,
    input  b,
    output y
);

assign y = a & b;

endmodule


//=====================================================
// Testbench
//=====================================================
module tb;

    // Testbench Signals
    reg a;
    reg b;
    wire y;

    // DUT (Device Under Test)
    and_gate dut (
        .a(a),
        .b(b),
        .y(y)
    );

    // Dump Waveform + Simulation
    initial begin
        $dumpfile("wave.vcd");      // DO NOT CHANGE THIS NAME
        $dumpvars(0, tb);           // Dump everything under tb

        $display("Simulation started");
        $display("---------------------------");
        $display("Time\tA\tB\tY");
        $display("---------------------------");

        a = 0; b = 0;
        #10 $display("%0t\t%b\t%b\t%b", $time, a, b, y);

        a = 0; b = 1;
        #10 $display("%0t\t%b\t%b\t%b", $time, a, b, y);

        a = 1; b = 0;
        #10 $display("%0t\t%b\t%b\t%b", $time, a, b, y);

        a = 1; b = 1;
        #10 $display("%0t\t%b\t%b\t%b", $time, a, b, y);

        $display("---------------------------");
        $display("Simulation Finished");

        #60;
        $finish;
    end

endmodule