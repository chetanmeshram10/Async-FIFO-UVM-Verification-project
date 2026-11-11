module rptr_empty #(parameter ADDR_WIDTH = 4)(
  input  logic                  rclk,
  input  logic                  rrst_n,
  input  logic                  rinc,
  input  logic [ADDR_WIDTH:0]   rq2_wptr,   // synced write pointer
  output logic                  rempty,
  output logic [ADDR_WIDTH-1:0] raddr,
  output logic [ADDR_WIDTH:0]   rptr        // pointer sent to write domain
);
  logic [ADDR_WIDTH:0] rbin, rbin_next, rgray_next, rptr_next;
  logic                rempty_val;

  assign raddr = rbin[ADDR_WIDTH-1:0];

`ifdef BUG_4
  assign rbin_next = rbin + rinc;                 // BUG_4: increments when empty
`else
  assign rbin_next = rbin + (rinc & ~rempty);
`endif

  assign rgray_next = (rbin_next >> 1) ^ rbin_next;

`ifdef BUG_1
  // BUG_1: binary pointer crosses the clock domain (matches wptr_full)
  assign rptr_next  = rbin_next;
  assign rempty_val = (rbin_next == rq2_wptr);
`else
  assign rptr_next  = rgray_next;
  assign rempty_val = (rgray_next == rq2_wptr);
`endif

  always_ff @(posedge rclk or negedge rrst_n)
    if (!rrst_n) begin
      rbin   <= '0;
      rptr   <= '0;
      rempty <= 1'b1;
    end else begin
      rbin   <= rbin_next;
      rptr   <= rptr_next;
      rempty <= rempty_val;
    end
endmodule