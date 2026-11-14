package fifo_pkg;
  timeunit 1ps; timeprecision 1ps;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "wr_item.sv"
  `include "rd_item.sv"
  `include "wr_sequencer.sv"
  `include "wr_driver.sv"
  `include "wr_monitor.sv"
  `include "wr_agent.sv"
  `include "rd_sequencer.sv"
  `include "rd_driver.sv"
  `include "rd_monitor.sv"
  `include "rd_agent.sv"
  `include "fifo_scoreboard.sv"
  `include "fifo_coverage.sv"
  `include "fifo_env.sv"
  `include "wr_seqs.sv"
  `include "rd_seqs.sv"
  `include "fifo_vseq.sv"
  `include "base_test.sv"
  `include "sanity_test.sv"
  `include "random_test.sv"
  `include "fill_drain_test.sv"
  `include "overflow_test.sv"
  `include "underflow_test.sv"
  `include "clk_ratio_test.sv"
endpackage