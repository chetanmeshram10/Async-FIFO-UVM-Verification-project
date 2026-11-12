interface rd_if #(parameter DW = 8)(input logic rclk, input logic rrst_n);
  logic          rinc;
  logic [DW-1:0] rdata;
  logic          rempty;

  initial rinc = 0;

  clocking drv_cb @(posedge rclk);
    default input #1step output #0;
    output rinc;
    input  rdata, rempty;
  endclocking

  clocking mon_cb @(posedge rclk);
    default input #1step;
    input rinc, rdata, rempty;
  endclocking
endinterface