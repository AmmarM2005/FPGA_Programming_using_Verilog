`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Virtual interface connecting testbench classes to DUT signals
// -----------------------------------------------------------------------------
interface alu_if(input logic clk, input logic rstn);
logic [3:0] A;
logic [3:0] B;
logic [2:0] OP;
logic [4:0] Y;
endinterface


// -----------------------------------------------------------------------------
// Transaction classes: base and extended demonstrating inheritance
// -----------------------------------------------------------------------------
class alu_txn;
    rand logic [3:0] A;
    rand logic [3:0] B;
    rand logic [2:0] OP;

// Basic constraint: keep B in 0..15, A in 0..15 (implicit)
    function string to_string();
    return $sformatf("A=%0h B=%0h OP=%0d", A, B, OP); //will print data in string format (sformatf)
endfunction
endclass

// Extended transaction: adds an expected result field and custom constructor
class alu_txn_exp extends alu_txn;              //extent is the keyword used for inheriting the features of parent class
logic [4:0] expected;

function void compute_expected();
    unique case (OP)
        3'd0: expected = {1'b0, A} + {1'b0, B};
        3'd1: expected = {1'b0, A} - {1'b0, B};
        3'd2: expected = {1'b0, A & B};
        3'd3: expected = {1'b0, A | B};
        3'd4: expected = {1'b0, A ^ B};
        3'd5: expected = {1'b0, (A << B[1:0]) & 4'hF};
        3'd6: expected = {1'b0, (A >> B[1:0])};
        3'd7: expected = {1'b0, A};
        default: expected = '0;
    endcase
endfunction
// override to_string
function string to_string();
    return $sformatf("A=%0h B=%0h OP=%0d EXPECTED=%0h", A, B, OP, expected);
endfunction
endclass

// -----------------------------------------------------------------------------
// Generator classes: base generator and an inherited constrained generator
// -----------------------------------------------------------------------------
class gen_base;
    mailbox mbox; // mailbox to send transactions to driver
    function new(mailbox mb = null);
     if (mb == null) 
            mbox = new(); 
        else 
            mbox = mb;
    endfunction

    task run(input int unsigned n_items = 10);
        alu_txn_exp t;                  // Transaction handler from child class
        repeat (n_items) begin
            t = new();
            //assert(t.randomize()) else $fatal("randomize failed");      //randomize will generate all rand modified variables, assert will make sure that the variables generated are valid
            t.compute_expected();
            mbox.put(t);
            $display("[GEN_BASE] put: %s", t.to_string());
            #5;
        end
    endtask
endclass

class gen_addsub extends gen_base;

    function new(mailbox mb);
        super.new(mb);   // call base class constructor, whenever i want to use members of parent class
    endfunction

    task run(input int unsigned n_items = 10);
        alu_txn_exp t;
        repeat(n_items) begin
            t = new();
            assert(t.randomize() with { OP inside {3'd0, 3'd1}; })
            else
                $fatal("Error in Operation Code Generation");
            t.compute_expected();
            mbox.put(t);
            $display("[GEN_ADDSUB] %s", t.to_string());
        end
    endtask
endclass
// -----------------------------------------------------------------------------
// Driver: reads txn from mailbox and drives DUT via virtual interface
// -----------------------------------------------------------------------------
class driver;
    mailbox mbox;
    virtual alu_if vif;

    function new(mailbox mb, virtual alu_if vif_h);
        mbox = mb; 
        vif = vif_h;
    endfunction

    task run();
        alu_txn_exp t;
        forever begin
            mbox.get(t); // blocking get
            // drive values for one cycle
            @(posedge vif.clk);             //waiting for positive edge of clock
            vif.A <= t.A;
            vif.B <= t.B;
            vif.OP <= t.OP;
            $display("[DRV] drove: %s at time %0t", t.to_string(), $time);
            // hold signals for a cycle
            @(posedge vif.clk);
            // optional: deassert
            vif.A <= '0; vif.B <= '0; vif.OP <= '0;
        end
    endtask
endclass


// -----------------------------------------------------------------------------
// Monitor: samples DUT interface and forwards observed transactions to scoreboard
// -----------------------------------------------------------------------------
class monitor;
    virtual alu_if vif;
    mailbox mbox_obs; // sends observed results to scoreboard
    function new(virtual alu_if vif_h, mailbox mb_obs);
        vif = vif_h; 
        mbox_obs = mb_obs;
    endfunction

    task run();
        alu_txn_exp obs;
        forever begin
        @(posedge vif.clk);
            obs = new();
            obs.A = vif.A;
            obs.B = vif.B;
            obs.OP = vif.OP;
            obs.expected = vif.Y; // observed value in 'expected' field for convenience
            // publish observed
            mbox_obs.put(obs);
        $display("[MON] observed: A=%0h B=%0h OP=%0d Y=%0h at time %0t", obs.A, obs.B, obs.OP, obs.expected, $time);
        #1;
        end
    endtask
endclass

// -----------------------------------------------------------------------------
// Scoreboard: compares expected (from txn) with observed (from monitor)
// we demonstrate two ways of providing expected: either via txn.expected (from generator)
// or by computing expected inside scoreboard. Here we'll receive expected via a "gold"
// mailbox that the generator also sends a copy to (for demonstration)
// -----------------------------------------------------------------------------
class scoreboard;
    mailbox mb_expected; // transactions with expected result
    mailbox mb_observed; // observed transactions from monitor
    
    function new(mailbox mb_e, mailbox mb_o);
        mb_expected = mb_e; 
        mb_observed = mb_o;
    endfunction


    task run(input int unsigned total);
        int unsigned passed = 0;
        int unsigned checked = 0;
        alu_txn_exp exp;
        alu_txn_exp obs;
        while (checked < total) begin
            mb_expected.get(exp);
            mb_observed.get(obs);
        // compute expected if not present
            exp.compute_expected();
            if (exp.expected === obs.expected) begin        //it will check case equality, will check for unknown
                passed++;
                $display("[SB] PASS: exp=%0h obs=%0h at time %0t", exp.expected, obs.expected, $time);
                end 
            else begin
                $display("[SB] FAIL: exp=%0h obs=%0h at time %0t -- details: exp(%s) obs(%s)", exp.expected, obs.expected, $time, exp.to_string(), obs.to_string());
            end
            checked++;
        end
        $display("[SB] Checked %0d transactions: %0d passed, %0d failed", checked, passed, checked-passed);
    endtask
endclass

// -----------------------------------------------------------------------------
// Environment: instantiates generator, driver, monitor, scoreboard and connects them
// -----------------------------------------------------------------------------
class env;
    virtual alu_if vif;
    mailbox mb_gen_drv; // generator -> driver
    mailbox mb_gen_gold; // generator -> scoreboard (expected)
    mailbox mb_mon_sb; // monitor -> scoreboard (observed)

    gen_base gen; // we'll instantiate base or derived generator
    driver drv;
    monitor mon;
    scoreboard sb;

    function new(input virtual alu_if vif_h, input bit use_addsub = 0);
        vif = vif_h;
        mb_gen_drv = new();
        mb_gen_gold = new();
        mb_mon_sb = new();
        
        if (use_addsub) 
            gen = new(mb_gen_drv); // will replace with derived below
         else 
            gen = new(mb_gen_drv);


        drv = new(mb_gen_drv, vif);
        mon = new(vif, mb_mon_sb);
        sb = new(mb_gen_gold, mb_mon_sb);
    endfunction


function void use_addsub_gen(input int unsigned seed = 0);
// reassign gen to a derived class instance that will still use mb_gen_drv
    gen = new(mb_gen_drv); // keep type as gen_base for simplicity
endfunction
endclass


// -----------------------------------------------------------------------------
// Top-level test that wires DUT and environment together and demonstrates inheritance
// -----------------------------------------------------------------------------
module tb_top;
  // clock / reset / interface / dut as before
  logic clk;
  logic rstn;
  alu_if dut_if(clk, rstn);
  ALU_4bit dut(.clk(clk), .rstn(rstn), .A(dut_if.A), .B(dut_if.B), .OP(dut_if.OP), .Y(dut_if.Y));

  // handles declared here (no initialization at declaration)
  env        etop;
  gen_addsub g_as;  
  mailbox    mb_gd;
  mailbox    mb_gold;

  initial begin
    clk = 0; rstn = 0;
    #10 rstn = 1;

    // create environment first (so its mailboxes exist)
    etop = new(dut_if);

    // now assign mailbox handles from environment (do NOT combine decl+assign)
    mb_gd   = etop.mb_gen_drv;
    mb_gold = etop.mb_gen_gold;

    // now safe to construct generator and pass the mailbox
   g_as = new(mb_gd);     // this is allowed inside initial block

    // start the processes (example)
    fork
      g_as.run(8);
      etop.drv.run();
      etop.mon.run();
      etop.sb.run(8);
    join_none
  end

  always #5 clk = ~clk;
endmodule