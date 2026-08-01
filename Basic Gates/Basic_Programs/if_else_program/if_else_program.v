module if_else_program(input A,B, output reg C);
always@(*)begin
    if(A==1'b1 && B==1'b1)begin
        C=1'b1;
    end
    else
        C=1'b0;
    end
endmodule