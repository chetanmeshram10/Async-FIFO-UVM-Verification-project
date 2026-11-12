interface wr_if #(parameter DW = 8)(input logic wclk, input logic wrst_n);
  logic          winc;
  logic [DW-1:0] wdata;
  logic          wfull;

  initial begin winc = 0; wdata = 0; end

  clocking drv_cb @(posedge wclk);
    default input #1step output #0;
    output winc, wdata;
    input  wfull;
  endclocking

  clocking mon_cb @(posedge wclk);
    default input #1step;
    input winc, wdata, wfull;
  endclocking
endinterface