`timescale 1ns/1ps

module led_shift_right_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

// Instantiate DUT
led_shift_right uut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

// Clock generation
always #5 clk = ~clk;

// Monitor shifting ONLY when it happens
always @(posedge clk) begin
    if (uut.count == 26'd10) begin   // use small value for simulation
        $display("Time=%0t | SHIFT OCCURRED | out=%b", $time, out);
    end
end

initial begin
    // Init
    clk = 0;
    rst = 1;
    in  = 8'b0000_0001;

    // Reset phase
    #20;
    rst = 0;

    // Run simulation
    #300;

    // Change pattern
    rst = 1;
    #10;
    in = 8'b0000_1000;
    rst = 0;

    #300;

    $finish;
end

endmodule