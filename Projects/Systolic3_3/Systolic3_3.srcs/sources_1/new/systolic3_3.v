module systolic3_3 (
    input clk,
    input rst,

    input [7:0] a0, a1, a2,
    input [7:0] b0, b1, b2,

    output [15:0] c00, c01, c02,
    output [15:0] c10, c11, c12,
    output [15:0] c20, c21, c22
);

// Internal wires
wire [7:0] a_wire [0:2][0:3];
wire [7:0] b_wire [0:3][0:2];

// Assign inputs
assign a_wire[0][0] = a0;
assign a_wire[1][0] = a1;
assign a_wire[2][0] = a2;

assign b_wire[0][0] = b0;
assign b_wire[0][1] = b1;
assign b_wire[0][2] = b2;

// PE grid
genvar i, j;
generate
    for (i = 0; i < 3; i = i + 1) begin : row
        for (j = 0; j < 3; j = j + 1) begin : col
            pe_module pe_inst (
                .clk(clk),
                .rst(rst),
                .a_in(a_wire[i][j]),
                .b_in(b_wire[i][j]),
                .a_out(a_wire[i][j+1]),
                .b_out(b_wire[i+1][j]),
                .c_out(
                    (i==0 && j==0) ? c00 :
                    (i==0 && j==1) ? c01 :
                    (i==0 && j==2) ? c02 :
                    (i==1 && j==0) ? c10 :
                    (i==1 && j==1) ? c11 :
                    (i==1 && j==2) ? c12 :
                    (i==2 && j==0) ? c20 :
                    (i==2 && j==1) ? c21 :
                                     c22
                )
            );
        end
    end
endgenerate

endmodule