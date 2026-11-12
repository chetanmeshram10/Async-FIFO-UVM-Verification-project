class fifo_env extends uvm_env;
  `uvm_component_utils(fifo_env)

  virtual wr_if wvif;
  virtual rd_if rvif;

  wr_agent wr_agt;
  rd_agent rd_agt;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual wr_if)::get(this, "", "wr_vif", wvif))
      `uvm_fatal("NOVIF", "wr_vif not set in config_db")
    if (!uvm_config_db#(virtual rd_if)::get(this, "", "rd_vif", rvif))
      `uvm_fatal("NOVIF", "rd_vif not set in config_db")

    // pass the interfaces down to the driver and monitor of each agent
    uvm_config_db#(virtual wr_if)::set(this, "wr_agt.*", "vif", wvif);
    uvm_config_db#(virtual rd_if)::set(this, "rd_agt.*", "vif", rvif);

    wr_agt = wr_agent::type_id::create("wr_agt", this);
    rd_agt = rd_agent::type_id::create("rd_agt", this);
  endfunction

  function void start_of_simulation_phase(uvm_phase phase);
    `uvm_info("ENV", "Env built: write and read agents connected", UVM_LOW)
  endfunction
endclass