// Code your testbench here
// or browse Examples

interface add_if;
  logic [3:0] a;
  logic [3:0] b;
  logic [7:0] mul;
  logic clk;
  
  modport DRV (input a,b, input mul,clk);
  
endinterface

class transaction;

 randc bit [3:0] a;
 randc bit [3:0] b;
 bit [7:0] mul;

  function void display();
    $display("a : %0d \t b: %0d \t mul: %0d",a,b,mul);
  endfunction


  function transaction copy();
    copy = new();
    copy.a = this.a;
    copy.b = this.b;
  endfunction

endclass


class driver;
  
  virtual add_if.DRV aif;
  mailbox #(transaction) mbx;
  transaction data;
  event next;

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction

  task run();
    forever begin
      mbx.get(data);
      @(posedge aif.clk);  
      aif.a <= data.a;
      aif.b <= data.b;
      $display("[DRV] : Interface Trigger");
      data.display();
      ->next;
    end
  endtask
  
  
endclass


class generator;

  event done; 
  transaction trans;
  mailbox #(transaction) mbx;
  int i = 0;
  event next;

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
    trans = new(); 
  endfunction

  task run();
    for(int i = 0; i < 10; i++) begin
      assert(trans.randomize()) else $display("RANDOMIZATION FAILED");
      $display("[GEN] : Data Sent to Driver");
      trans.display();
      mbx.put(trans.copy); 
      @(next);
    end
   ->done;
  endtask

endclass


 
module tb;
  
  generator gen;
  mailbox #(transaction) mbx;
  event done;


  add_if aif();
  driver drv;
  
  top dut (.a(aif.a), .b(aif.b), .mul(aif.mul), .clk(aif.clk));
 
  initial begin
    mbx = new();
    drv = new(mbx);
    gen = new(mbx);
    drv.next = gen.next;
    drv.aif = aif;
    done = gen.done;
    
  end

  initial begin
    fork
      gen.run();
      drv.run();
    join_none 
    wait(done.triggered);
    $finish;
  end


  initial begin
    aif.clk <= 0;
  end
  
  always #10 aif.clk <= ~aif.clk;
  
  initial begin
    $dumpfile("dump.vcd"); 
    $dumpvars;
  end
  
endmodule
