module wptr_full #(parameter ADDR_WIDTH = 4)(
  input  logic                  wclk,
  input  logic                  wrst_n,
  input  logic                  winc,
  input  logic [ADDR_WIDTH:0]   wq2_rptr,   // synced read pointer
  output logic                  wfull,
  output logic [ADDR_WIDTH-1:0] waddr,
  output logic [ADDR_WIDTH:0]   wptr        // pointer sent to read domain
);
  logic [ADDR_WIDTH:0] wbin, wbin_next, wgray_next, wptr_next;
  logic                wfull_val;

  assign waddr = wbin[ADDR_WIDTH-1:0];

`ifdef BUG_3
  assign wbin_next = wbin + winc;                 // BUG_3: ignores wfull
`else
  assign wbin_next = wbin + (winc & ~wfull);
`endif

  assign wgray_next = (wbin_next >> 1) ^ wbin_next;

`ifdef BUG_1
  // BUG_1: binary pointer crosses the clock domain instead of Gray
  assign wptr_next  = wbin_next;
  assign wfull_val  = (wbin_next[ADDR_WIDTH] != wq2_rptr[ADDR_WIDTH]) &&
                      (wbin_next[ADDR_WIDTH-1:0] == wq2_rptr[ADDR_WIDTH-1:0]);
`elsif BUG_2
  // BUG_2: full compare missing the MSB inversion
  assign wptr_next  = wgray_next;
  assign wfull_val  = (wgray_next == wq2_rptr);
`else
  assign wptr_next  = wgray_next;
  assign wfull_val  = (wgray_next ==
                       {~wq2_rptr[ADDR_WIDTH:ADDR_WIDTH-1], wq2_rptr[ADDR_WIDTH-2:0]});
`endif

  always_ff @(posedge wclk or negedge wrst_n)
    if (!wrst_n) begin
      wbin  <= '0;
      wptr  <= '0;
      wfull <= 1'b0;
    end else begin
      wbin  <= wbin_next;
      wptr  <= wptr_next;
      wfull <= wfull_val;
    end
endmodule