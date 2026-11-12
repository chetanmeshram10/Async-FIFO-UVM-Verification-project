class wr_monitor extends uvm_monitor;
  `uvm_component_utils(wr_monitor)

  virtual wr_if vif;
  uvm_analysis_port #(wr_item) ap;
  int unsigned count;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual wr_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "wr_monitor: vif not set")
  endfunction

  task run_phase(uvm_phase phase);
    wr_item t;
    wait (vif.wrst_n === 1'b1);
    forever begin
      @(vif.mon_cb);
      if (vif.wrst_n === 1'b1 && vif.mon_cb.winc === 1'b1 && vif.mon_cb.wfull === 1'b0) begin
        t = wr_item::type_id::create("t");
        t.data = vif.mon_cb.wdata;
        count++;
        `uvm_info("WR_MON", $sformatf("WRITE accepted: data=0x%02h", t.data), UVM_MEDIUM)
        ap.write(t);
      end
    end
  endtask

  function void report_phase(uvm_phase phase);
    `uvm_info("WR_MON", $sformatf("Total accepted writes: %0d", count), UVM_LOW)
  endfunction
endclass