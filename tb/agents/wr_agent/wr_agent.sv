class wr_agent extends uvm_agent;
  `uvm_component_utils(wr_agent)

  wr_sequencer sqr;
  wr_driver    drv;
  wr_monitor   mon;
  uvm_analysis_port #(wr_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = wr_monitor::type_id::create("mon", this);
    if (get_is_active() == UVM_ACTIVE) begin
      sqr = wr_sequencer::type_id::create("sqr", this);
      drv = wr_driver::type_id::create("drv", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    ap = mon.ap;
    if (get_is_active() == UVM_ACTIVE)
      drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass