`timescale 1ns / 1ps

module simple_round_robin_arbiter(
    input clk,
    input rst_n,
    input [3:0] req,
    output reg [3:0] grant,
    output reg valid
);

    reg [1:0] pointer;  // 0,1,2,3
    
    // Rotated priority selection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant <= 4'b0000;
            valid <= 1'b0;
            pointer <= 2'b00;
        end else begin
            // Check requests starting from pointer
            case (pointer)
                2'b00: begin // Check 0,1,2,3
                    if (req[0]) begin
                        grant <= 4'b0001;
                        pointer <= 2'b01;
                    end else if (req[1]) begin
                        grant <= 4'b0010;
                        pointer <= 2'b10;
                    end else if (req[2]) begin
                        grant <= 4'b0100;
                        pointer <= 2'b11;
                    end else if (req[3]) begin
                        grant <= 4'b1000;
                        pointer <= 2'b00;
                    end else begin
                        grant <= 4'b0000;
                    end
                end
                2'b01: begin // Check 1,2,3,0
                    if (req[1]) begin
                        grant <= 4'b0010;
                        pointer <= 2'b10;
                    end else if (req[2]) begin
                        grant <= 4'b0100;
                        pointer <= 2'b11;
                    end else if (req[3]) begin
                        grant <= 4'b1000;
                        pointer <= 2'b00;
                    end else if (req[0]) begin
                        grant <= 4'b0001;
                        pointer <= 2'b01;
                    end else begin
                        grant <= 4'b0000;
                    end
                end
                2'b10: begin // Check 2,3,0,1
                    if (req[2]) begin
                        grant <= 4'b0100;
                        pointer <= 2'b11;
                    end else if (req[3]) begin
                        grant <= 4'b1000;
                        pointer <= 2'b00;
                    end else if (req[0]) begin
                        grant <= 4'b0001;
                        pointer <= 2'b01;
                    end else if (req[1]) begin
                        grant <= 4'b0010;
                        pointer <= 2'b10;
                    end else begin
                        grant <= 4'b0000;
                    end
                end
                2'b11: begin // Check 3,0,1,2
                    if (req[3]) begin
                        grant <= 4'b1000;
                        pointer <= 2'b00;
                    end else if (req[0]) begin
                        grant <= 4'b0001;
                        pointer <= 2'b01;
                    end else if (req[1]) begin
                        grant <= 4'b0010;
                        pointer <= 2'b10;
                    end else if (req[2]) begin
                        grant <= 4'b0100;
                        pointer <= 2'b11;
                    end else begin
                        grant <= 4'b0000;
                    end
                end
            endcase
            
            // Set valid based on if any request was granted
            valid <= (req != 4'b0000);
        end
    end

endmodule