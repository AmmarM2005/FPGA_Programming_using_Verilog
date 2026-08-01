`timescale 1ns / 1ps
module ALU_8_bit_tb;
reg  [7:0]A;
reg  [7:0]B;
reg  [2:0]OP;
wire [15:0] R;

//DUT INSTANTIATION
ALU_8_bit u1 (A,B,OP,R);
    initial begin   
        OP=3'b000;
        A=8'd8;
        B=8'd5;
        #5;
        $display("Addition of %0d and %0d is %0d at time %0t", A,B,R,$time);
        A=8'd255;
        B=8'd100;
        #5;
        $display("Addition of %0d and %0d is %0d at time %0t", A,B,R,$time);
        
        OP=3'b001;
        A=8'd8;
        B=8'd5;
        #5;
        $display("Subtraction of %0d and %0d is %0d at time %0t", A,B,R,$time);
        A=8'd255;
        B=8'd100;
        #5;
        $display("Subtraction of %0d and %0d is %0d at time %0t", A,B,R,$time);
        
        OP=3'b010;
        A=8'd8;
        B=8'd5;
        #5;
        $display("Mulitplication of %0d and %0d is %0d at time %0t", A,B,R,$time);     
        A=8'd255;
        B=8'd100;
        #5;   
        $display("Multiplication of %0d and %0d is %0d at time %0t", A,B,R,$time);

        OP=3'b011;
        A=8'd8;
        B=8'd5;
        #5;
        $display("Inversion of %0d and %0d is %0d at time %0t", A,B,R,$time);
        A=8'd255;
        B=8'd100;
        #5;
        $display("Inversion of %0d and %0d is %0d at time %0t", A,B,R,$time);
        
        OP=3'b100;
        A=8'd8;
        B=8'd5;
        #5;
        $display("Logical And of %0d and %0d is %0d at time %0t", A,B,R,$time);
        A=8'd255;
        B=8'd100;
        #5;
        $display("Logical And of %0d and %0d is %0d at time %0t", A,B,R,$time);
        
        OP=3'b101;
        A=8'd8;
        B=8'd5;
        #5;
        $display("Or of %0d and %0d is %0d at time %0t", A,B,R,$time);
        A=8'd255;
        B=8'd100;
        #5;
        $display("Or of %0d and %0d is %0d at time %0t", A,B,R,$time);
        
        OP=3'b110;
        A=8'd8;
        B=8'd5;
        #5;
        $display("XOR of %0d and %0d is %0d at time %0t", A,B,R,$time);
        A=8'd255;
        B=8'd100;
        #5;
        $display("XOR of %0d and %0d is %0d at time %0t", A,B,R,$time);
        
        OP=3'b111;
        A=8'd8;
        B=8'd5;
        #5;
        $display("Default testing of %0d and %0d is %0d at time %0t", A,B,R,$time);   
        A=8'd255;
        B=8'd100;
        #5;
        $display("Default testing of %0d and %0d is %0d at time %0t", A,B,R,$time); 
        end      
endmodule
