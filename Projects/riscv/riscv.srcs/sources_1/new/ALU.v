// Fix - make Y a wire driven by combinational logic:
module alu(
    input  [31:0] A, B,
    input  [3:0]  alu_ctrl,
    output [31:0] Y,      // ← wire, not reg
    output        zero
);
    reg [31:0] alu_out;   // internal reg for case statement

    assign Y    = alu_out;
    assign zero = (alu_out == 32'b0);  // both see same value, same delta

    always @(*) begin
        case (alu_ctrl)
            4'b0000: alu_out = A & B;
            4'b0001: alu_out = A | B;
            4'b0010: alu_out = A + B;
            4'b0011: alu_out = A ^ B;
            4'b0110: alu_out = A - B;
            4'b0111: alu_out = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;
            4'b1000: alu_out = A << B[4:0];
            4'b1001: alu_out = A >> B[4:0];
            4'b1010: alu_out = $signed(A) >>> B[4:0];
            default: alu_out = 32'b0;
        endcase
    end
endmodule