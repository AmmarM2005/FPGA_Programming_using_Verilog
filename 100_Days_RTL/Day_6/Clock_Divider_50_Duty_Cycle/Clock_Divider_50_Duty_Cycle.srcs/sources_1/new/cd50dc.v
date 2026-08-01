module cd50dc(input clk, rst, output reg [3:0]led);
reg [23:0]divider; //bcz 100M/2^24 = 5.96  
always@(posedge clk or posedge rst)begin
    if(rst)begin
        divider <=24'd0;
        led     <=4'd0;
    end 
    else begin
        divider<=divider+1;
    end
    if (divider == 24'hFFFFFF)begin
        led <= led+1;
    end
end
endmodule
    