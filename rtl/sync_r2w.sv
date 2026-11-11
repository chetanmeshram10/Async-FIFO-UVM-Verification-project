// Read pointer -> write clock domain
module sync_r2w #(parameter ADDR_WIDTH = 4)(
  input  logic                wclk,
  input  logic                wrst_n,
  input  logic [ADDR_WIDTH:0] rptr,
  output logic [ADDR_WIDTH:0] wq2_rptr
);
  logic [ADDR_WIDTH:0] wq1_rptr;

  always_ff @(posedge wclk or negedge wrst_n)
    if (!wrst_n) {wq2_rptr, wq1_rptr} <= '0;
    else         {wq2_rptr, wq1_rptr} <= {wq1_rptr, rptr};
endmodule