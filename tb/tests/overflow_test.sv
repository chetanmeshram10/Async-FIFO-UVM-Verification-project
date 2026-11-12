class overflow_test extends base_test;
  `uvm_component_utils(overflow_test)

  localparam int DEPTH = 16;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    wr_burst_seq wb, extra;
    rd_burst_seq rb;
    phase.raise_objection(this);

    wb = wr_burst_seq::type_id::create("wb");
    wb.num_items = DEPTH;
    wb.start(env.wr_agt.sqr);          // exactly full
    #300ns;

    env.wr_agt.drv.respect_full = 0;   // now fire writes at a full FIFO
    extra = wr_burst_seq::type_id::create("extra");
    extra.num_items = 8;
    extra.start(env.wr_agt.sqr);
    env.wr_agt.drv.respect_full = 1;
    #300ns;

    rb = rd_burst_seq::type_id::create("rb");
    rb.num_items = DEPTH;              // the 16 original words must come back intact
    rb.start(env.rd_agt.sqr);
    #500ns;
    phase.drop_objection(this);
  endtask
endclass