class base_test extends uvm_test;
  `uvm_component_utils(base_test)

  fifo_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = fifo_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("TEST", "Day 3 skeleton running", UVM_LOW)
    #1us;
    phase.drop_objection(this);
  endtask
endclass