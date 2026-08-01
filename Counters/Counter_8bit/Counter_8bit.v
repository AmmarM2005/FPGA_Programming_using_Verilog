module Counter_8bit(
    input clk,
    input rst,
    input up_down,       
    output reg [7:0] count
);
initial count=8'b00000000;
always @(posedge clk or posedge rst) begin
    if (rst)
        count <= 8'b00000000;
    else begin
        if (up_down)
            count <= count + 1;   
        else
            count <= count - 1;   
    end
end
endmodule
