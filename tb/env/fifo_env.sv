class fifo_env extends uvm_env;
  `uvm_component_utils(fifo_env)

  virtual wr_if wvif;
  virtual rd_if rvif;

  wr_agent        wr_agt;
  rd_agent        rd_agt;
  fifo_scoreboard sb;
  fifo_coverage   cov;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual wr_if)::get(this, "", "wr_vif", wvif))
      `uvm_fatal("NOVIF", "wr_vif not set in config_db")
    if (!uvm_config_db#(virtual rd_if)::get(this, "", "rd_vif", rvif))
      `uvm_fatal("NOVIF", "rd_vif not set in config_db")

    uvm_config_db#(virtual wr_if)::set(this, "wr_agt.*", "vif", wvif);
    uvm_config_db#(virtual rd_if)::set(this, "rd_agt.*", "vif", rvif);

    wr_agt = wr_agent::type_id::create("wr_agt", this);
    rd_agt = rd_agent::type_id::create("rd_agt", this);
    sb     = fifo_scoreboard::type_id::create("sb", this);
    cov    = fifo_coverage::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    wr_agt.ap.connect(sb.wr_export);
    rd_agt.ap.connect(sb.rd_export);
    wr_agt.ap.connect(cov.wr_export);
    rd_agt.ap.connect(cov.rd_export);
  endfunction

  function void start_of_simulation_phase(uvm_phase phase);
    `uvm_info("ENV", "Env built: agents + scoreboard + coverage connected", UVM_LOW)
  endfunction
endclass