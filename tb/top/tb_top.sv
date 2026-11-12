module tb_top;
  timeunit 1ps; timeprecision 1ps;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import fifo_pkg::*;

  int  wclk_ps = 10000;   // 100 MHz default
  int  rclk_ps = 27000;   // ~37 MHz default
  logic wclk = 0, rclk = 0, wrst_n = 0, rrst_n = 0;

  wr_if wif (wclk, wrst_n);
  rd_if rif (rclk, rrst_n);

  async_fifo #(.DATA_WIDTH(8), .ADDR_WIDTH(4)) dut (
    .wclk(wclk), .wrst_n(wrst_n), .winc(wif.winc),
    .wdata(wif.wdata), .wfull(wif.wfull),
    .rclk(rclk), .rrst_n(rrst_n), .rinc(rif.rinc),
    .rdata(rif.rdata), .rempty(rif.rempty));

  // clocks + reset (periods overridable with +WCLK_PS= / +RCLK_PS=)
  initial begin
    void'($value$plusargs("WCLK_PS=%d", wclk_ps));
    void'($value$plusargs("RCLK_PS=%d", rclk_ps));
    fork
      forever #(wclk_ps/2) wclk = ~wclk;
      forever #(rclk_ps/2) rclk = ~rclk;
    join_none
    repeat (4) @(negedge wclk); wrst_n = 1;
    repeat (4) @(negedge rclk); rrst_n = 1;
  end

  // UVM start
  initial begin
    uvm_config_db#(virtual wr_if)::set(null, "*", "wr_vif", wif);
    uvm_config_db#(virtual rd_if)::set(null, "*", "rd_vif", rif);
    run_test();
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top);
  end
endmodule