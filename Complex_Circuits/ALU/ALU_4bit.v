module ALU_4bit(
    input clk,
    input rstn,
    input [3:0]A,
    input [3:0]B,
    input [2:0]OP,
    output reg [4:0]Y
);

always @(posedge clk, negedge rstn) begin
if (!rstn)begin 
    Y<=5'd0;
end else begin
    case (OP)
    3'd0: Y <= ({1'b0, A} + {1'b0, B});        // add
    3'd1: Y <= ({1'b0, A} - {1'b0, B});        // sub
    3'd2: Y <= ({1'b0, A & B});                // AND
    3'd3: Y <= ({1'b0, A | B});                // OR
    3'd4: Y <= ({1'b0, A ^ B});                // XOR
    3'd5: Y <= ({1'b0, (A << B[1:0]) & 4'hF}); // left shift 
    3'd6: Y <= ({1'b0, (A >> B[1:0])});        // right shift
    3'd7: Y <= ({1'b0, A});                    // pass-through
    default: Y <= 5'd0;
endcase
end
end 
endmodule