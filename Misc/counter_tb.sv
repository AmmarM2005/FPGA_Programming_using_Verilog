module counter (
    input  logic clk,
    input  logic rst,
    output logic [3:0] count
);

always_ff @(posedge clk or posedge rst) begin
    if (rst)
        count <= 4'd0;
    else
        count <= count + 1;
end

endmodule

module tb;

logic clk;
logic rst;
logic [3:0] count;

counter dut (
    .clk(clk),
    .rst(rst),
    .count(count)
);

always #5 clk = ~clk;

initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb);

    clk = 0;
    rst = 1;

    $display("Simulation Started");
    $display("Time\tReset\tCount");
    $monitor("%0t\t%b\t%0d", $time, rst, count);

    #12 rst = 0;

    #100;

    $display("Simulation Finished");
    $finish;
end

endmodule