bind async_fifo fifo_assertions #(.AW(ADDR_WIDTH)) u_sva (
  .wclk(wclk), .wrst_n(wrst_n), .winc(winc), .wfull(wfull), .wptr(wptr),
  .rclk(rclk), .rrst_n(rrst_n), .rinc(rinc), .rempty(rempty), .rptr(rptr));