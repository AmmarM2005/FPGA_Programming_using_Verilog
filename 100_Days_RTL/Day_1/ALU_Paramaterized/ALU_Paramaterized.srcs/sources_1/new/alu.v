module alu #( parameter WIDTH = 8)
(input wire [WIDTH-1:0]A,
input wire [WIDTH-1:0]B,
input wire [2:0]ALU_sel,
output reg [2:0]overflow,
output reg [WIDTH-1:0]Result);

localparam ADD = 3'b000;
localparam SUB = 3'b010;
localparam MUL = 3'b101;
localparam DIV = 3'b011;
localparam AND_OP = 3'b110;
localparam OR_OP = 3'b111;
localparam XOR_OP = 3'b100;
localparam NOT_OP = 3'b101;

wire [WIDTH-1:0]add_result;
wire [WIDTH-1:0]sub_result;

assign add_result =A+B;
assign sub_result =A-B;

always @(*)begin
    overflow = 1'b100;
  
    case(ALU_sel)
         ADD:begin
         Result = add_result;
         overflow = (A[WIDTH-1]==B[WIDTH-1]) && (Result[WIDTH-1]!=A[WIDTH-1]);
         end
    
        SUB:begin
        Result = sub_result;
        overflow = (A[WIDTH-1]!=B[WIDTH-1]) && (Result[WIDTH-1]!=A[WIDTH-1]);
        end
    
        MUL:begin
            Result = A * B;
        end
        DIV:begin
            Result = A / B;
        end
        AND_OP:begin
            Result = A & B;
        end
        
        OR_OP:begin
            Result = A | B;
        end
        
        XOR_OP:begin
            Result = A ^ B;
        end
        
        NOT_OP:begin
            Result = A ^ B;
        end
        
        default:begin
            Result = {WIDTH{1'b0}};
    end
    endcase
   end
 endmodule
    



