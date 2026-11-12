class wr_driver extends uvm_driver #(wr_item);
  `uvm_component_utils(wr_driver)

  virtual wr_if vif;
  bit respect_full = 1;   // 1: hold request until accepted; 0: fire once, drop if full

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual wr_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "wr_driver: vif not set")
    void'(uvm_config_db#(bit)::get(this, "", "respect_full", respect_full));
  endfunction

  task run_phase(uvm_phase phase);
    wr_item t;
    vif.drv_cb.winc <= 1'b0;
    wait (vif.wrst_n === 1'b1);
    @(vif.drv_cb);
    forever begin
      seq_item_port.get_next_item(t);
      drive(t);
      seq_item_port.item_done();
    end
  endtask

  task drive(wr_item t);
    bit accepted;
    // idle gap
    repeat (t.delay) begin
      vif.drv_cb.winc <= 1'b0;
      @(vif.drv_cb);
    end
    // request; the sampled wfull is the value the DUT saw at that edge
    do begin
      vif.drv_cb.winc  <= 1'b1;
      vif.drv_cb.wdata <= t.data;
      @(vif.drv_cb);
      accepted = !vif.drv_cb.wfull;
    end while (respect_full && !accepted);
    vif.drv_cb.winc <= 1'b0;   // overridden in the same timestep if the next item is back-to-back
  endtask
endclass