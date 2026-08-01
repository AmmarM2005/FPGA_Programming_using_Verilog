`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.11.2025 14:06:00
// Design Name: 
// Module Name: ALU_8_bit_tb
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
    logic [7:0]A,B;
    logic [2:0]OP;
    logic [15:0]R;
endinterface

class txn;
    rand bit[7:0] A,B;
    rand bit[2:0] OP;
    bit [15:0] R;
    
    function void print(input string tag="");
        $display("[%s] A=%0d, B=%0d, OP=%0d, Result = %0d at %0t", tag,A,B,OP,R,$time);
    endfunction
endclass

class generator;
    txn tr;
    mailbox gen2drv;
    
    function new(mailbox mbx);
        gen2drv = mbx;
    endfunction
    
    task run();
        repeat(10) begin
            tr = new();
            tr.randomize();
            tr.print("Gen");
            gen2drv.put(tr);
        end
    endtask
    
    class driver;
        txn tr;
        mailbox gen2drv;
        virtual interface alu_if vif;
        
        function new(virtual interface alu_if vif, mailbox mbx);
            this.vif = vif;
            gen2drv = mbx;
        endfunction
        
        task run();
            forever begin 
                tr = new();
                gen2drv.get(tr);
                vif.A=tr.A;
                vif.B=tr.B;
                vif.OP=tr.OP;
                tr.print("DRV");
                #10;
                end
        endtask
endclass

class monitor;
    txn tr;
        mailbox gen2drv;
        virtual interface alu_if vif;
        
        function new(virtual interface alu_if vif, mailbox mbx);
            this.vif = vif;
            mon2scb = mbx;
        endfunction
        
        task run();
            forever begin
                tr=new();
                tr.A=vif.A;
                tr.B=vif.B;
                tr.OP=vif.OP;
                tr.result = vif.result;
                mon2scb.put(tr);
                tr.print("MON");
                #9.95;
             end
        endtask
endclass
           
class scoreboards;
    txn tr;
    mailbox mon2scb;
    logic [15:0] exp_result;
    
    function new (mailbox mbx);
        mon2scb = mbx;
    endfunction
    
    task run();
        forever begin 
            tr = new();
            mon2scb.get(tr);
            if(tr.OP == 3'b000)
                exp_result = tr.A + tr.B;
            else
                if(tr.OP==3'b001)
                    exp_result = tr.A - tr.B;
                else
                    if(tr.OP == 3'b010)
                exp_result = tr.A + tr.B;
                     
