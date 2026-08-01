module Counter_4bit(
    input load,
    input clk,
    input rst,
    input up_down,
    input [4:0]din,       
    output reg [3:0] count
);

initial count=4'b0000;
always @(posedge clk or posedge rst) begin
    if (rst)
        count <= 4'b0000;
    else begin
    if (load)
        din <= din;
        if (up_down)
            count <= count + 1;   
        else
            count <= count - 1;   
    end
end
endmodule
