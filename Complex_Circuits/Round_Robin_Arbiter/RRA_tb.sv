`timescale 1ns / 1ps

module tb_round_robin_arbiter;
    
    parameter N = 4;
    reg clk = 0;
    reg rst_n = 0;
    reg [N-1:0] req = 0;
    wire [N-1:0] grant;
    wire valid;
    
    // DUT instantiation
    simple_round_robin_arbiter #(N) dut (
        .clk(clk),
        .rst_n(rst_n),
        .req(req),
        .grant(grant),
        .valid(valid)
    );
    
    // Clock generation
    always #5 clk = ~clk;
    
    // Test sequence
    initial begin
        // Initialize
        $dumpfile("arbiter.vcd");
        $dumpvars(0, tb_round_robin_arbiter);
        
        // Reset
        rst_n = 0;
        repeat(2) @(posedge clk);
        rst_n = 1;
        @(posedge clk);
        
        // Test 1: Single request rotation
        $display("Test 1: Single request rotation");
        for (int i = 0; i < N*2; i++) begin
            req = (1 << (i % N));
            @(posedge clk);
            #1;
            $display("Time=%0t: req=%b, grant=%b, valid=%b", 
                     $time, req, grant, valid);
            if (valid !== 1'b1 || grant !== req)
                $error("Single request test failed!");
        end
        
        // Test 2: Multiple requests
        $display("\nTest 2: Multiple simultaneous requests");
        req = 4'b1111;  // All requesters
        repeat(8) begin
            @(posedge clk);
            #1;
            $display("Time=%0t: req=%b, grant=%b, valid=%b", 
                     $time, req, grant, valid);
            if (valid !== 1'b1 || $countones(grant) !== 1)
                $error("Multiple requests test failed!");
        end
        
        // Test 3: No requests
        $display("\nTest 3: No requests");
        req = 0;
        repeat(3) @(posedge clk);
        #1;
        if (valid !== 1'b0 || grant !== 0)
            $error("No request test failed!");
        
        // Test 4: Random patterns
        $display("\nTest 4: Random patterns");
        repeat(20) begin
            req = $random;
            @(posedge clk);
            #1;
            $display("Time=%0t: req=%b, grant=%b, valid=%b", 
                     $time, req, grant, valid);
            
            if (req == 0) begin
                if (valid !== 0 || grant !== 0)
                    $error("Zero request test failed!");
            end else begin
                if (valid !== 1 || $countones(grant) !== 1 || (grant & req) === 0)
                    $error("Random test failed!");
            end
        end
        
        $display("\nAll tests passed!");
        $finish;
    end
    
endmodule