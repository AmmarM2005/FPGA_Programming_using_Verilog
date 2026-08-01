module SD_4bit_Mealy (input clk, rst, input data_in, output reg detected);
    parameter S0 = 2'b00,  
              S1 = 2'b01,  
              S2 = 2'b10,  
              S3 = 2'b11;  
    reg [1:0] current_state, next_state;
    always @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= S0;
        else
            current_state <= next_state;
    end
    // Next state logic and output (Mealy: output depends on state AND input)
    always @(*) begin
        case (current_state)
            S0: begin
                detected = 1'b0;
                next_state = (data_in == 1'b1) ? S1 : S0;
            end
            S1: begin
                detected = 1'b0;
                next_state = (data_in == 1'b0) ? S2 : S1;
            end
            S2: begin
                detected = 1'b0;
                next_state = (data_in == 1'b1) ? S3 : S0;
            end
            S3: begin
                // Mealy output: goes high when in S3 AND input is 1
                detected = (data_in == 1'b1) ? 1'b1 : 1'b0;
                next_state = (data_in == 1'b1) ? S1 : S2;
            end
            default: begin
                detected = 1'b0;
                next_state = S0;
            end
        endcase
    end
endmodule