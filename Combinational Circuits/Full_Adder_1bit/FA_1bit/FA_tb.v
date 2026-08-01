`timescale 1ns / 1ps

// Full adder module (DUT)
module full_adder(
    input a,
    input b,
    input cin,
    output sum,
    output cout
);
    
    // Dataflow implementation
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
    
endmodule

// Testbench module
module tb();

   reg A, B, Cin;
   wire Sum, Cout;

   // DUT instance with proper module name
   full_adder uut(.a(A), .b(B), .cin(Cin), .sum(Sum), .cout(Cout));

   // Stimulus Generation (all 8 input combinations)
   initial begin
      // Test case 1
      A = 0; B = 0; Cin = 0;
      #5;
      
      // Test case 2
      A = 0; B = 0; Cin = 1;
      #5;
      
      // Test case 3
      A = 0; B = 1; Cin = 0;
      #5;
      
      // Test case 4
      A = 0; B = 1; Cin = 1;
      #5;
      
      // Test case 5
      A = 1; B = 0; Cin = 0;
      #5;
      
      // Test case 6
      A = 1; B = 0; Cin = 1;
      #5;
      
      // Test case 7
      A = 1; B = 1; Cin = 0;
      #5;
      
      // Test case 8
      A = 1; B = 1; Cin = 1;
      #5;
      
      // End simulation
      $finish;
   end

   // Monitor outputs
   initial begin
      $monitor("Time = %0tns: A=%0b, B=%0b, Cin=%0b | Sum=%0b, Cout=%0b",
                $time, A, B, Cin, Sum, Cout);
   end

endmodule