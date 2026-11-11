// Write pointer -> read clock domain
module sync_w2r #(parameter ADDR_WIDTH = 4)(
  input  logic                rclk,
  input  logic                rrst_n,
  input  logic [ADDR_WIDTH:0] wptr,
  output logic [ADDR_WIDTH:0] rq2_wptr
);
  logic [ADDR_WIDTH:0] rq1_wptr;

  always_ff @(posedge rclk or negedge rrst_n)
    if (!rrst_n) {rq2_wptr, rq1_wptr} <= '0;
    else         {rq2_wptr, rq1_wptr} <= {rq1_wptr, wptr};
endmodule