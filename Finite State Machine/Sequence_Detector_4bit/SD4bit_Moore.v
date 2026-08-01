module SD4bit_Moore (input clk, rst, input data_in, output reg detected);
     parameter S0 = 3'b000,  
              S1 = 3'b001,  
              S2 = 3'b010,  
              S3 = 3'b011,  
              S4 = 3'b100;  
    reg [2:0] current_state, next_state;
    always @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= S0;
        else
            current_state <= next_state;
    end
    always @(*) begin
        case (current_state)
            S0: next_state = (data_in == 1'b1) ? S1 : S0;
            S1: next_state = (data_in == 1'b0) ? S2 : S1;
            S2: next_state = (data_in == 1'b1) ? S3 : S0;
            S3: next_state = (data_in == 1'b1) ? S4 : S2;
            S4: next_state = (data_in == 1'b1) ? S1 : S2;  
            default: next_state = S0;
        endcase
    end
    always @(*) begin
        case (current_state)
            S4: detected = 1'b1;  
            default: detected = 1'b0;
        endcase
    end
endmodule




