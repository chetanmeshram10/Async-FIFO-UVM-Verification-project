class rd_agent extends uvm_agent;
  `uvm_component_utils(rd_agent)

  rd_sequencer sqr;
  rd_driver    drv;
  rd_monitor   mon;
  uvm_analysis_port #(rd_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = rd_monitor::type_id::create("mon", this);
    if (get_is_active() == UVM_ACTIVE) begin
      sqr = rd_sequencer::type_id::create("sqr", this);
      drv = rd_driver::type_id::create("drv", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    ap = mon.ap;
    if (get_is_active() == UVM_ACTIVE)
      drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass