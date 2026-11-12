class sanity_test extends base_test;
  `uvm_component_utils(sanity_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    wr_rand_seq wseq;
    rd_rand_seq rseq;

    phase.raise_objection(this);
    wseq = wr_rand_seq::type_id::create("wseq");
    rseq = rd_rand_seq::type_id::create("rseq");
    wseq.num_items = 20;
    rseq.num_items = 20;

    fork
      wseq.start(env.wr_agt.sqr);
      rseq.start(env.rd_agt.sqr);
    join

    #200ns;   // let the monitors finish
    phase.drop_objection(this);
  endtask
endclass