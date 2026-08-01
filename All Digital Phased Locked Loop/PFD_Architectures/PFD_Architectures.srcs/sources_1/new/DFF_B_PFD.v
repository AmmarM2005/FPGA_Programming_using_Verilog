module DFF_B_PFD (
    input clk_ref,
    input clk_fb,
    input rst,
    output reg up,
    output reg down
);

always @(posedge clk_ref or posedge rst)
begin
    if (rst)
        up <= 1'b0;
    else
        up <= 1'b1;
end

always @(posedge clk_fb or posedge rst)
begin
    if (rst)
        down <= 1'b0;
    else
        down <= 1'b1;
end

always @(up or down)
begin
    if (up && down)
    begin
        up <= 1'b0;
        down <= 1'b0;
    end
end

endmodule