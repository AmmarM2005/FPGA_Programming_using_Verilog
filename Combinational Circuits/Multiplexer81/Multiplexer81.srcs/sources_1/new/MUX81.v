module Mux_8to1_Gate(
    input [7:0] I,          
    input [2:0] S,        
    output Y                
);
    wire [7:0] w;     
    and (w[0], I[0], ~S[2], ~S[1], ~S[0]); 
    and (w[1], I[1], ~S[2], ~S[1], S[0]);  
    and (w[2], I[2], ~S[2], S[1], ~S[0]); 
    and (w[3], I[3], ~S[2], S[1], S[0]);   
    and (w[4], I[4], S[2], ~S[1], ~S[0]);  
    and (w[5], I[5], S[2], ~S[1], S[0]);   
    and (w[6], I[6], S[2], S[1], ~S[0]);   
    and (w[7], I[7], S[2], S[1], S[0]);    
    or (Y, w[0], w[1], w[2], w[3], 
           w[4], w[5], w[6], w[7]);
endmodule
