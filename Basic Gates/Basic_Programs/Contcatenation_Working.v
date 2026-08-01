module concatenation(input A, input B, input C, output wire [3:0]Z);
wire p;
wire q;
wire r;
wire s;

assign p = A&B ;
assign q = A|B ;
assign r = A^B ;
assign s = ~C ;

assign Z={p,q,r,s};
endmodule