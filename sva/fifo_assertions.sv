module fifo_assertions #(parameter int AW = 4)(
  input logic          wclk, wrst_n, winc, wfull,
  input logic [AW:0]   wptr,
  input logic          rclk, rrst_n, rinc, rempty,
  input logic [AW:0]   rptr
);
  int unsigned n_full, n_empty, n_wr_at_full, n_rd_at_empty;

  // ---------- reset behaviour ----------
  a_wr_reset : assert property (@(posedge wclk)
      (!wrst_n && !$past(wrst_n)) |-> (wfull === 1'b0 && wptr === '0))
    else $error("SVA_FAIL a_wr_reset: wfull/wptr not at reset value");

  a_rd_reset : assert property (@(posedge rclk)
      (!rrst_n && !$past(rrst_n)) |-> (rempty === 1'b1 && rptr === '0))
    else $error("SVA_FAIL a_rd_reset: rempty/rptr not at reset value");

  a_wfull_low_after_reset : assert property (@(posedge wclk)
      $rose(wrst_n) |=> !wfull)
    else $error("SVA_FAIL a_wfull_low_after_reset: wfull high right after reset");

  // ---------- Gray pointers: at most one bit changes per clock ----------
  a_wptr_gray : assert property (@(posedge wclk) disable iff (!wrst_n)
      $countones(wptr ^ $past(wptr)) <= 1)
    else $error("SVA_FAIL a_wptr_gray: write pointer changed by more than 1 bit");

  a_rptr_gray : assert property (@(posedge rclk) disable iff (!rrst_n)
      $countones(rptr ^ $past(rptr)) <= 1)
    else $error("SVA_FAIL a_rptr_gray: read pointer changed by more than 1 bit");

  // ---------- no pointer movement on an illegal access ----------
  a_no_wr_when_full : assert property (@(posedge wclk) disable iff (!wrst_n)
      (winc && wfull) |=> $stable(wptr))
    else $error("SVA_FAIL a_no_wr_when_full: write pointer moved while full");

  a_no_rd_when_empty : assert property (@(posedge rclk) disable iff (!rrst_n)
      (rinc && rempty) |=> $stable(rptr))
    else $error("SVA_FAIL a_no_rd_when_empty: read pointer moved while empty");

  // ---------- were the interesting conditions actually exercised? ----------
  c_full        : cover property (@(posedge wclk) disable iff (!wrst_n) $rose(wfull))      n_full++;
  c_empty       : cover property (@(posedge rclk) disable iff (!rrst_n) $rose(rempty))     n_empty++;
  c_wr_at_full  : cover property (@(posedge wclk) disable iff (!wrst_n) winc && wfull)     n_wr_at_full++;
  c_rd_at_empty : cover property (@(posedge rclk) disable iff (!rrst_n) rinc && rempty)    n_rd_at_empty++;

  final $display("SVA_COVER full_events=%0d empty_events=%0d wr_while_full=%0d rd_while_empty=%0d",
                 n_full, n_empty, n_wr_at_full, n_rd_at_empty);
endmodule