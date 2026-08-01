`timescale 1ns / 1ps

module tb_d_flip_flop;

    logic clk;
    logic reset;
    logic D;
    wire Q;

   
    d_flip_flop uut (
        .clk(clk),
        .reset(reset),
        .D(D),
        .Q(Q)
    );

    
    initial clk = 0;
    always #5 clk = ~clk;

    
    initial begin
        $dumpfile("d_flip_flop.vcd"); 
        $dumpvars(0, tb_d_flip_flop);

        reset = 1;
        D = 0;
        #10;

        reset = 0;  
        D = 1;      
        #10;

        D = 0;      
        #10;

        D = 1;
        #10;

        reset = 1;  
        #10;
        reset = 0;
        #10;

        $finish;
    end

endmodule
