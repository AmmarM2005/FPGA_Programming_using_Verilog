module fsm (
    input  wire clk,       // clock
    input  wire reset,     // async reset
    input  wire in,        // input signal
    output reg  out        // output signal
);

    // State encoding
    typedef enum logic [1:0] {
        S0 = 2'b00,
        S1 = 2'b01,
        S2 = 2'b10
    } state_t;

    state_t current_state, next_state;

    // State register (sequential logic)
    always @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= S0;
        else
            current_state <= next_state;
    end

    // Next-state logic (combinational)
    always @(*) begin
        case (current_state)
            S0: next_state = in ? S1 : S0;
            S1: next_state = in ? S2 : S0;
            S2: next_state = in ? S2 : S1;
            default: next_state = S0;
        endcase
    end

    // Output logic (Moore: depends only on state)
    always @(*) begin
        case (current_state)
            S0: out = 0;
            S1: out = 0;
            S2: out = 1;
            default: out = 0;
        endcase
    end

endmodule