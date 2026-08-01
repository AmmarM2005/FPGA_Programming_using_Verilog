module led_shift_right(input clk, rst, [7:0]in, output reg [7:0]out);
reg [25:0]count;
always@(posedge clk)begin
    if (rst)begin
        count<=0;
    end
    else if (count==26'd25_000_000)begin
        count<=0;
    end
    else
        count <= count + 1;
end
always@(posedge clk)begin
    if(rst)begin
        out<=in;
    end
    else if(count==26'd25_000_000)begin
        if (out==8'b00000001)
              out<=8'b10000000;
        
    else
              out<=out>>1;
    end
end
endmodule
