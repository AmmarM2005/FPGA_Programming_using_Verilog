module DPA_B_PFD (
    input clk_ref,
    input clk_fb,
    input rst,
    output up,
    output down
);

reg q_ref;
reg q_fb;

wire up_raw;
wire down_raw;

always @(posedge clk_ref or posedge rst)
begin
    if (rst)
        q_ref <= 1'b0;
    else
        q_ref <= 1'b1;
end

always @(posedge clk_fb or posedge rst)
begin
    if (rst)
        q_fb <= 1'b0;
    else
        q_fb <= 1'b1;
end

always @(posedge (q_ref & q_fb) or posedge rst)
begin
    if (rst)
    begin
        q_ref <= 1'b0;
        q_fb <= 1'b0;
    end
    else
    begin
        q_ref <= 1'b0;
        q_fb <= 1'b0;
    end
end

assign up_raw = q_ref & ~q_fb;
assign down_raw = q_fb & ~q_ref;

DPA dpa_up (
    .in(up_raw),
    .out(up)
);

DPA dpa_down (
    .in(down_raw),
    .out(down)
);

endmodule