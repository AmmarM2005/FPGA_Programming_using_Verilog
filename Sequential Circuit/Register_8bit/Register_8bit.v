module usr_8bit (
    input clk, rst,
    input [1:0] mode,
    input [7:0] par_in,
    input ser_left, ser_right,
    output reg [7:0] out
);

    initial out = 8'b0;
    always @(posedge clk or posedge rst) begin
        if (rst)
            out <= 8'b0;
        else begin
            case (mode)
                2'b00: out <= out; // Hold
                2'b01: out <= {out[6:0], ser_right}; // Shift Left
                2'b10: out <= {ser_left, out[7:1]}; // Shift Right
                2'b11: out <= par_in; // Parallel Load
                default: out <= out; // Safety
            endcase
        end
    end
endmodule
