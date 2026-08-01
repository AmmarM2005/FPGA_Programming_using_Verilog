module Replication_Operator(input enable, output [3:0]out);
assign out = {4{enable}};
endmodule