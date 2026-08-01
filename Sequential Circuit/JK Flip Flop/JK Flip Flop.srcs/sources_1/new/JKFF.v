module JKFF(clk,rst,j,k,q,qbar);
        input clk,rst,j,k;
        output reg q;
        output qbar;
        always @(posedge clk or posedge rst)
        begin 
               if (rst)
                    q=0;
               else begin
                    case({j,k})
                         2'b00: q=q;    // Hold
                         2'b01: q=0;    // Reset
                         2'b10: q=1;    // Set
                         2'b11: q=~q;   // Toggle
                    endcase
               end
        end
        assign qbar=~q;
endmodule