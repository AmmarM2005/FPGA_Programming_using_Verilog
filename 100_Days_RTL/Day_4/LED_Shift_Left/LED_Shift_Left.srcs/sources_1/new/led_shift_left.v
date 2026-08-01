module led_shift_left(input clk, rst,[7:0]in, output reg [7:0]out);
reg [25:0]count;
always@(posedge clk)begin
    if(rst)begin
        count<=0;
    end
    else if(count <=26'd25_00_000)
        count<=0;
    else
        count<=count+1;
        
end
always@(posedge clk)begin
    if(rst)begin
        out<=in;
    end
    else if(count<=26'd25_00_000)begin
        if (out==8'b0000000)
           out<=8'b0000001;
        else
            out<=out<<1;
    end
end
endmodule
           

        