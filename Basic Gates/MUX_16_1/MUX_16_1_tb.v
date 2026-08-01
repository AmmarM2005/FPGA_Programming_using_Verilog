`timescale 1ns / 1ps

module tb();
   reg[15:0]I;
   reg [3:0]sel;
   wire Y;
   //DUT instance 
     mux16_1 u1(I , sel , Y);
   // Stimulus Generation
   initial begin 
      I = 16'h0001;
      #5;
      I = 16'hfffe;
      sel = 4'h0;
      #5;
 //-----------------
      sel = 4'h1;
      I = 16'hfffd;
      #5;
      I = 16'h0002;
      #5; 
 //-----------------
      sel = 4'h2;
      I = 16'hfffb;
      #5;
      I = 16'h0004;
      #5;
 //-----------------
      sel = 4'h3;
      I = 16'hfff7;
      #5;
      I = 16'h0008;
      #5;
 //-----------------
      sel = 4'h4;
      I = 16'hffef;
      #5;
      I = 16'h0010;
      #5;
 //-----------------
      sel = 4'h5;
      I = 16'hffdf;
      #5;
      I = 16'h0020;
      #5;
 //-----------------
      sel = 4'h6;
      I = 16'hffbf;
      #5;
      I = 16'h0040;
      #5;
//-----------------
      sel = 4'h7;
      I = 16'hff7f;
      #5;
      I = 16'h0080;
      #5;
//-----------------
      sel = 4'h8;
      I = 16'hfeff;
      #5;
      I = 16'h0100;
      #5;
//-----------------
      sel = 4'h9;
      I = 16'hfdff;
      #5;
      I = 16'h0200;
      #5;
//-----------------
      sel = 4'hA;
      I = 16'hfbff;
      #5;
      I = 16'h0400;
      #5;
//-----------------
      sel = 4'hB;
      I = 16'hf7ff;
      #5;
      I = 16'h0800;
      #5; 
//-----------------
      sel = 4'hC;
      I = 16'hefff;
      #5;
      I = 16'h1000;
      #5;
//-----------------
      sel = 4'hD;
      I = 16'hdfff;
      #5;
      I = 16'h2000;
      #5;
//-----------------
      sel = 4'hE;
      I = 16'hbfff;
      #5;
      I = 16'h4000;
      #5;
//-----------------
      sel = 4'hF;
      I = 16'h7fff;
      #5;
      I = 16'h8000;
      #5;
      end
      
      initial begin  
            $monitor ("%4h,%0h,%0b @time=", I,sel,Y,$time);
      end
endmodule