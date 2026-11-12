class rd_driver extends uvm_driver #(rd_item);
  `uvm_component_utils(rd_driver)

  virtual rd_if vif;
  bit  respect_empty = 1;  // 1: hold request until accepted; 0: fire once, drop if empty
  time last_edge;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual rd_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "rd_driver: vif not set")
    void'(uvm_config_db#(bit)::get(this, "", "respect_empty", respect_empty));
  endfunction

  task tick();
    @(vif.drv_cb);
    last_edge = $time;
  endtask

  task run_phase(uvm_phase phase);
    rd_item t;
    vif.drv_cb.rinc <= 1'b0;
    wait (vif.rrst_n === 1'b1);
    tick();
    forever begin
      seq_item_port.get_next_item(t);
      drive(t);
      seq_item_port.item_done();
    end
  endtask

  task drive(rd_item t);
    bit accepted;
    if ($time != last_edge) tick();

    repeat (t.delay) begin
      vif.drv_cb.rinc <= 1'b0;
      tick();
    end

    do begin
      vif.drv_cb.rinc <= 1'b1;
      tick();
      accepted = !vif.drv_cb.rempty;
    end while (respect_empty && !accepted);

    vif.drv_cb.rinc <= 1'b0;
  endtask
endclass