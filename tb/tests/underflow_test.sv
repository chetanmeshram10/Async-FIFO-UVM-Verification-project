class underflow_test extends base_test;
  `uvm_component_utils(underflow_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    rd_burst_seq dummy, rb;
    wr_burst_seq wb;
    phase.raise_objection(this);

    env.rd_agt.drv.respect_empty = 0;  // read an empty FIFO
    dummy = rd_burst_seq::type_id::create("dummy");
    dummy.num_items = 8;
    dummy.start(env.rd_agt.sqr);
    env.rd_agt.drv.respect_empty = 1;
    #200ns;

    wb = wr_burst_seq::type_id::create("wb");
    wb.num_items = 10;
    wb.start(env.wr_agt.sqr);
    #300ns;

    rb = rd_burst_seq::type_id::create("rb");
    rb.num_items = 10;                 // FIFO must still behave normally after the illegal reads
    rb.start(env.rd_agt.sqr);
    #500ns;
    phase.drop_objection(this);
  endtask
endclass