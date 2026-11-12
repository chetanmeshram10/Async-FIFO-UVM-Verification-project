class rd_monitor extends uvm_monitor;
  `uvm_component_utils(rd_monitor)

  virtual rd_if vif;
  uvm_analysis_port #(rd_item) ap;
  int unsigned count;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual rd_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "rd_monitor: vif not set")
  endfunction

  task run_phase(uvm_phase phase);
    rd_item t;
    wait (vif.rrst_n === 1'b1);
    forever begin
      @(vif.mon_cb);
      // rdata is combinational from memory, so the value sampled at the accepting edge is the word being popped
      if (vif.rrst_n === 1'b1 && vif.mon_cb.rinc === 1'b1 && vif.mon_cb.rempty === 1'b0) begin
        t = rd_item::type_id::create("t");
        t.data = vif.mon_cb.rdata;
        count++;
        `uvm_info("RD_MON", $sformatf("READ accepted:  data=0x%02h", t.data), UVM_MEDIUM)
        ap.write(t);
      end
    end
  endtask

  function void report_phase(uvm_phase phase);
    `uvm_info("RD_MON", $sformatf("Total accepted reads: %0d", count), UVM_LOW)
  endfunction
endclass