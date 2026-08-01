module Shift_Register(
input sin,
input rst,
input clk,
input dir,
output [7:0]leds
);
reg [7:0]shift_reg;
    always@(posedge clk ,negedge rst)begin
        if(!rst)
            shift_reg=8'd0;
        else
        if(dir)
            shift_reg <= {sin,shift_reg[7:1]};
        else
            shift_reg <={shift_reg[6:0],sin};
        end
        assign leds=shift_reg; 
endmodule

