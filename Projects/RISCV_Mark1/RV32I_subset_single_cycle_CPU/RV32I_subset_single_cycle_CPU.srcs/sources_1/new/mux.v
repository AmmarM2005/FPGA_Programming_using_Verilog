module mux(input [31:0]a,b,input sel,output [31:0]y);
assign y=sel?b:a;
endmodule