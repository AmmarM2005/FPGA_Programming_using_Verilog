// Digital Controlled Oscillator (DCO) for ADPLL
// Features:
// - Multi-bit frequency control word (FCW)
// - Phase accumulator architecture
// - Fine and coarse frequency tuning
// - Dithering for fractional frequency synthesis
// - Clock enable output for digital circuits

module dco_adpll #(
    parameter PHASE_WIDTH = 32,      // Phase accumulator width
    parameter FCW_WIDTH = 32,        // Frequency Control Word width
    parameter FINE_WIDTH = 8,        // Fine tuning bits
    parameter COARSE_WIDTH = 8       // Coarse tuning bits
)(
    input wire clk,                  // Reference clock input
    input wire rst_n,                // Active low reset
    input wire enable,               // DCO enable
    
    // Frequency control inputs
    input wire [FCW_WIDTH-1:0] fcw,  // Frequency Control Word
    input wire [FINE_WIDTH-1:0] fine_tune,   // Fine frequency adjustment
    input wire [COARSE_WIDTH-1:0] coarse_tune, // Coarse frequency adjustment
    
    // Control signals
    input wire dither_enable,        // Enable dithering for fractional-N
    input wire [1:0] dither_order,   // Dithering order (0=off, 1=1st, 2=2nd, 3=3rd)
    
    // Outputs
    output reg dco_clk,              // DCO output clock
    output wire dco_clk_enable,      // Clock enable signal
    output wire [PHASE_WIDTH-1:0] phase_out, // Current phase (for monitoring)
    output wire overflow             // Phase accumulator overflow indicator
);

    // Internal signals
    reg [PHASE_WIDTH-1:0] phase_acc;
    reg [PHASE_WIDTH-1:0] phase_acc_prev;
    wire [PHASE_WIDTH-1:0] frequency_word;
    wire [PHASE_WIDTH-1:0] phase_inc;
    wire phase_overflow;
    
    // Dithering signals
    reg [15:0] lfsr;                 // Linear Feedback Shift Register for dithering
    wire [7:0] dither_value;
    reg [7:0] dither_shaped;
    
    // Fine and coarse tuning scaled values
    wire [PHASE_WIDTH-1:0] fine_scaled;
    wire [PHASE_WIDTH-1:0] coarse_scaled;
    
    //===========================================
    // Frequency Control Word Generation
    //===========================================
    // Scale fine and coarse tuning to phase accumulator width
    assign fine_scaled = {{(PHASE_WIDTH-FINE_WIDTH){1'b0}}, fine_tune};
    assign coarse_scaled = {{(PHASE_WIDTH-COARSE_WIDTH-8){1'b0}}, coarse_tune, 8'b0};
    
    // Combine all frequency control inputs
    assign frequency_word = fcw + fine_scaled + coarse_scaled;
    
    //===========================================
    // Dithering Module (for Fractional-N synthesis)
    //===========================================
    // LFSR for pseudo-random number generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            lfsr <= 16'hACE1; // Non-zero seed
        else if (enable && dither_enable)
            // Polynomial: x^16 + x^15 + x^13 + x^4 + 1
            lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[14] ^ lfsr[12] ^ lfsr[3]};
    end
    
    assign dither_value = lfsr[7:0];
    
    // Dither shaping (noise shaping for fractional spurs reduction)
    reg [7:0] dither_error1, dither_error2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dither_shaped <= 8'b0;
            dither_error1 <= 8'b0;
            dither_error2 <= 8'b0;
        end else if (enable && dither_enable) begin
            case (dither_order)
                2'b00: dither_shaped <= 8'b0;  // No dither
                2'b01: dither_shaped <= dither_value; // First order
                2'b10: begin  // Second order
                    dither_shaped <= dither_value + dither_error1;
                    dither_error1 <= dither_value;
                end
                2'b11: begin  // Third order (MASH 1-1-1)
                    dither_shaped <= dither_value + dither_error1 - dither_error2;
                    dither_error1 <= dither_value;
                    dither_error2 <= dither_error1;
                end
            endcase
        end
    end
    
    // Apply dithering to phase increment
    assign phase_inc = frequency_word + 
                      (dither_enable ? {{(PHASE_WIDTH-8){1'b0}}, dither_shaped} : {PHASE_WIDTH{1'b0}});
    
    //===========================================
    // Phase Accumulator
    //===========================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= {PHASE_WIDTH{1'b0}};
            phase_acc_prev <= {PHASE_WIDTH{1'b0}};
        end else if (enable) begin
            phase_acc_prev <= phase_acc;
            phase_acc <= phase_acc + phase_inc;
        end
    end
    
    // Detect overflow (carry out from MSB)
    assign phase_overflow = (phase_acc < phase_acc_prev) && enable;
    assign overflow = phase_overflow;
    
    //===========================================
    // DCO Clock Generation
    //===========================================
    // Generate clock from MSB of phase accumulator
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dco_clk <= 1'b0;
        else if (enable)
            dco_clk <= phase_acc[PHASE_WIDTH-1];
    end
    
    // Clock enable generated on phase overflow
    assign dco_clk_enable = phase_overflow;
    
    // Phase output for monitoring/debugging
    assign phase_out = phase_acc;

endmodule


//===========================================
// DCO Controller (Optional wrapper with calibration)
//===========================================
module dco_controller #(
    parameter PHASE_WIDTH = 32,
    parameter FCW_WIDTH = 32,
    parameter FINE_WIDTH = 8,
    parameter COARSE_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire enable,
    
    // Target frequency control
    input wire [FCW_WIDTH-1:0] target_fcw,
    
    // Error input from phase detector
    input wire signed [15:0] phase_error,
    input wire error_valid,
    
    // Loop filter outputs (proportional and integral paths)
    output reg [FINE_WIDTH-1:0] fine_tune,
    output reg [COARSE_WIDTH-1:0] coarse_tune,
    output reg [FCW_WIDTH-1:0] fcw_out,
    
    // Status
    output reg locked
);

    // Loop filter integrator
    reg signed [31:0] integrator;
    reg signed [15:0] proportional;
    
    // Loop filter coefficients (Kp, Ki)
    localparam signed [15:0] KP = 16'sd256;   // Proportional gain
    localparam signed [15:0] KI = 16'sd8;     // Integral gain
    
    // Lock detector
    reg [15:0] lock_counter;
    localparam LOCK_THRESHOLD = 16'd100;
    localparam LOCK_COUNT = 16'd1000;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            integrator <= 32'sd0;
            proportional <= 16'sd0;
            fine_tune <= {FINE_WIDTH{1'b0}};
            coarse_tune <= {COARSE_WIDTH{1'b0}};
            fcw_out <= {FCW_WIDTH{1'b0}};
            locked <= 1'b0;
            lock_counter <= 16'd0;
        end else if (enable) begin
            fcw_out <= target_fcw;
            
            if (error_valid) begin
                // Proportional path
                proportional <= (phase_error * KP) >>> 8;
                
                // Integral path
                integrator <= integrator + ((phase_error * KI) >>> 8);
                
                // Apply to fine and coarse tuning
                fine_tune <= proportional[FINE_WIDTH-1:0];
                
                // Coarse from integrator
                if (integrator[31])  // Negative
                    coarse_tune <= {COARSE_WIDTH{1'b0}};
                else if (integrator > (1 << (COARSE_WIDTH+8)))
                    coarse_tune <= {COARSE_WIDTH{1'b1}};
                else
                    coarse_tune <= integrator[COARSE_WIDTH+7:8];
                
                // Lock detection
                if ((phase_error < LOCK_THRESHOLD) && (phase_error > -LOCK_THRESHOLD)) begin
                    if (lock_counter < LOCK_COUNT)
                        lock_counter <= lock_counter + 1'b1;
                    else
                        locked <= 1'b1;
                end else begin
                    lock_counter <= 16'd0;
                    locked <= 1'b0;
                end
            end
        end
    end

endmodule


//===========================================
// Testbench Example
//===========================================
`ifdef SIMULATION
module dco_adpll_tb;
    reg clk, rst_n, enable;
    reg [31:0] fcw;
    reg [7:0] fine_tune, coarse_tune;
    reg dither_enable;
    reg [1:0] dither_order;
    
    wire dco_clk, dco_clk_enable, overflow;
    wire [31:0] phase_out;
    
    // Instantiate DCO
    dco_adpll #(
        .PHASE_WIDTH(32),
        .FCW_WIDTH(32),
        .FINE_WIDTH(8),
        .COARSE_WIDTH(8)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .fcw(fcw),
        .fine_tune(fine_tune),
        .coarse_tune(coarse_tune),
        .dither_enable(dither_enable),
        .dither_order(dither_order),
        .dco_clk(dco_clk),
        .dco_clk_enable(dco_clk_enable),
        .phase_out(phase_out),
        .overflow(overflow)
    );
    
    // Clock generation (100 MHz reference)
    initial clk = 0;
    always #5 clk = ~clk;
    
    // Test sequence
    initial begin
        rst_n = 0;
        enable = 0;
        fcw = 32'h10000000;  // Divide by 16
        fine_tune = 8'd0;
        coarse_tune = 8'd0;
        dither_enable = 0;
        dither_order = 2'b00;
        
        #100;
        rst_n = 1;
        #50;
        enable = 1;
        
        // Test 1: Basic operation
        #10000;
        
        // Test 2: Frequency change
        fcw = 32'h20000000;  // Divide by 8
        #10000;
        
        // Test 3: Fine tuning
        fine_tune = 8'd50;
        #10000;
        
        // Test 4: Enable dithering
        dither_enable = 1;
        dither_order = 2'b10;  // Second order
        #10000;
        
        $finish;
    end
    
    // Monitor
    initial begin
        $monitor("Time=%0t fcw=%h phase=%h dco_clk=%b overflow=%b", 
                 $time, fcw, phase_out, dco_clk, overflow);
    end

endmodule
`endif