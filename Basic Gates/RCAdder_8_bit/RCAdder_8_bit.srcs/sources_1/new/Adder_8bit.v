module FA(A,B,C,SUM,CARRY);
input A;
input B;
input C;
output SUM;
output CARRY;
assign SUM=A^B^C;
assign CARRY=(A&B)|(A&C)|(B&C);
endmodule

module adder_8bit(A,B,CIN,SUM,CARRY);
input [7:0]A;
input [7:0]B;
input CIN;
output [7:0]SUM;
output [7:0]CARRY;
FA FA0(A[0],B[0],CIN,SUM[0],CARRY[0]);
FA FA1(A[1],B[1],CARRY[0],SUM[1],CARRY[1]);
FA FA2(A[2],B[2],CARRY[1],SUM[2],CARRY[2]);
FA FA3(A[3],B[3],CARRY[2],SUM[3],CARRY[3]);
FA FA4(A[4],B[4],CARRY[3],SUM[4],CARRY[4]);
FA FA5(A[5],B[5],CARRY[4],SUM[5],CARRY[5]);
FA FA6(A[6],B[6],CARRY[5],SUM[6],CARRY[6]);
FA FA7(A[7],B[7],CARRY[6],SUM[7],CARRY[7]);
endmodule