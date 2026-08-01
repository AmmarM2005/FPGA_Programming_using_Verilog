module full_subtractor_bl( input a, b, cin,output reg d,bo );
    always @(a or b or cin) begin
         if (cin == 1'b0) begin
            if ((a == 1'b1 && b == 1'b0) || (a == 1'b0 && b == 1'b1)) begin
                d = 1'b1;
            end else begin
                d = 1'b0;
            end
        end else begin  
            if ((a == 1'b1 && b == 1'b0) || (a == 1'b0 && b == 1'b1)) begin
                d = 1'b0;
            end else begin
                d = 1'b1;
            end
        end
        if ((a == 1'b0 && b == 1'b1) || 
            (a == 1'b0 && cin == 1'b1) || 
            (b == 1'b1 && cin == 1'b1)) begin
            bo = 1'b1;
        end else begin
            bo = 1'b0;
        end
    end
endmodule

