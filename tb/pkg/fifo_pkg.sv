package fifo_pkg;
  timeunit 1ps; timeprecision 1ps;   // removes the Xcelium TSNSPK warning

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // items
  `include "wr_item.sv"
  `include "rd_item.sv"
  // sequencers, drivers, monitors, agents
  `include "wr_sequencer.sv"
  `include "wr_driver.sv"
  `include "wr_monitor.sv"
  `include "wr_agent.sv"
  `include "rd_sequencer.sv"
  `include "rd_driver.sv"
  `include "rd_monitor.sv"
  `include "rd_agent.sv"
  // env
  `include "fifo_env.sv"
  // sequences
  `include "wr_seqs.sv"
  `include "rd_seqs.sv"
  // tests
  `include "base_test.sv"
  `include "sanity_test.sv"
endpackage