`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.11.2025 14:02:14
// Design Name: 
// Module Name: tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

interface alu_if();
    logic [7:0] A,B;
    logic [2:0]OP;
    logic [15:0]result;
endinterface

class txn;
    rand bit[7:0] A,B; //every random is generated, before repeating any paattern
    randc bit [2:0]OP;
    bit [15:0] result; //this is output, we dont want it to be random
    
    function void print(input string tag="");
        $display("[%s] A= %0d, B=%0d, OP = %0d, Result = %0d at %0t", tag, A,B,OP,result,$time);
    endfunction 
endclass

class generator;
    txn tr;             
    mailbox gen2drv;
    
    function new(mailbox mbx);  //constructor, memory allocated i.e 4 bit(A,B,OP,result)
        gen2drv = mbx;
    endfunction                 // function is used when we
    
    task run();                 //task used when time basis work is required
        repeat(10) begin        //this loop will repeat 10 times
            tr = new();
            tr.randomize();
            tr.print("Gen");
            gen2drv.put(tr);    //this will put values of gen in driver
          end    
    endtask
endclass
    
class driver;                                                   
    txn tr;
    mailbox gen2drv;
    virtual interface alu_if vif;                               //this denotes interface
    
    function new(virtual interface alu_if vif, mailbox mbx);    //constructor, memory allocated
        this.vif = vif;
        gen2drv = mbx;
    endfunction
    
    task run();
        
        forever begin                   //whenever stimulus comes, it will generate
   //         tr = new();
            gen2drv.get(tr);
            vif.A= tr.A;
            vif.B = tr.B;
            vif.OP = tr.OP;
            tr.print("DRV");
            #10;
          end
     endtask
 endclass
 
 
class monitor;
    txn tr;
    mailbox mon2scb;
    virtual interface alu_if vif;                               //
    
    function new(virtual interface alu_if vif, mailbox mbx);
        this.vif = vif;
        mon2scb = mbx;
    endfunction
    
    task run();
         forever begin
            tr = new();        
            tr.A = vif.A;
            tr.B = vif.B;
            tr.OP = vif.OP;
            tr.result = vif.result;
            mon2scb.put(tr);
            tr.print("MON");
            #9.95;
          end
    endtask
endclass

class scoreboard;
    txn tr;
    mailbox mon2scb;
    logic [15:0] exp_result;
    
    function new(mailbox mbx);
        mon2scb = mbx;
    endfunction
    
    task run();
        forever begin
  //        tr = new();
            mon2scb.get(tr);
            case (tr.OP)
                  3'b000: exp_result = {8'h00, tr.A} + {8'h00, tr.B};   // add
                  3'b001: exp_result = {8'h00, tr.A} - {8'h00, tr.B};   // sub
                  3'b010: exp_result = tr.A * tr.B;                     // mul (16-bit)
                  3'b011: exp_result = {8'h00, ~tr.A};                  // inv
                  3'b100: exp_result = {8'h00, tr.A} & {8'h00, tr.B};   // and
                  3'b101: exp_result = {8'h00, tr.A} | {8'h00, tr.B};   // or
                  3'b110: exp_result = {8'h00, tr.A} ^ {8'h00, tr.B};   // xor
                  3'b111: exp_result = {8'h00, tr.A} << tr.B;           // sll
            endcase
            
       if(exp_result == tr.result)
       begin
            tr.print("PASS");
            $display ("Expected  Output %0b",exp_result);
            $display ("Simuluted Output %0b",tr.result);
       end     
       else
       begin
            tr.print("FAIL");
            $display ("Generated A =    %0b",tr.A);
            $display ("Generated B =    %0b",tr.B);
            $display ("Expected  Output %0b",exp_result);
            
            $display ("Simuluted Output %0b",tr.result);
       end     
       #9.95;
   end
 endtask
endclass

module tb( );
    alu_if aluif();
       
    // DUT Mapping
        alu_8bit u1(aluif.A, aluif.B, aluif.OP, aluif.result);
    mailbox gen2drv = new();
    mailbox mon2scb= new();
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    
    initial begin
        gen= new(gen2drv);
        drv = new(aluif,gen2drv);
        mon = new(aluif,mon2scb);
        scb = new(mon2scb);
        fork
            gen.run();
            drv.run();
            mon.run();
            scb.run();
        join_none
    end
    
    initial begin
    #100;
    $finish;
    end
    initial begin
        $dumpfile("alu_tb.vcd");  // name of VCD file
        $dumpvars(0, tb);         // record all signals in 'tb' and below
end
    
endmodule