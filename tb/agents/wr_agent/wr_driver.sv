class wr_driver extends uvm_driver #(wr_item);
  `uvm_component_utils(wr_driver)

  virtual wr_if vif;
  bit  respect_full = 1;   // 1: hold request until accepted; 0: fire once, drop if full
  time last_edge;          // time of the last clock edge this driver synced to

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual wr_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "wr_driver: vif not set")
    void'(uvm_config_db#(bit)::get(this, "", "respect_full", respect_full));
  endfunction

  // wait for the next clock edge and remember when it happened
  task tick();
    @(vif.drv_cb);
    last_edge = $time;
  endtask

  task run_phase(uvm_phase phase);
    wr_item t;
    vif.drv_cb.winc <= 1'b0;
    wait (vif.wrst_n === 1'b1);
    tick();
    forever begin
      seq_item_port.get_next_item(t);
      drive(t);
      seq_item_port.item_done();
    end
  endtask

  task drive(wr_item t);
    bit accepted;
    // An item that arrives between clock edges must wait for the next edge first.
    // Otherwise that edge is counted as "accepted" before winc has reached the DUT.
    if ($time != last_edge) tick();

    repeat (t.delay) begin
      vif.drv_cb.winc <= 1'b0;
      tick();
    end

    do begin
      vif.drv_cb.winc  <= 1'b1;
      vif.drv_cb.wdata <= t.data;
      tick();
      accepted = !vif.drv_cb.wfull;   // wfull as the DUT saw it at this edge
    end while (respect_full && !accepted);

    vif.drv_cb.winc <= 1'b0;   // overridden in the same timestep if the next item is back-to-back
  endtask
endclass