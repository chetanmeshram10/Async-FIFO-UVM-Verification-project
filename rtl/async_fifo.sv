module async_fifo #(
  parameter DATA_WIDTH = 8,
  parameter ADDR_WIDTH = 4
)(
  // write domain
  input  logic                  wclk,
  input  logic                  wrst_n,
  input  logic                  winc,
  input  logic [DATA_WIDTH-1:0] wdata,
  output logic                  wfull,
  // read domain
  input  logic                  rclk,
  input  logic                  rrst_n,
  input  logic                  rinc,
  output logic [DATA_WIDTH-1:0] rdata,
  output logic                  rempty
);
  logic [ADDR_WIDTH-1:0] waddr, raddr;
  logic [ADDR_WIDTH:0]   wptr, rptr, wq2_rptr, rq2_wptr;

  sync_r2w #(.ADDR_WIDTH(ADDR_WIDTH)) u_sync_r2w (
    .wclk(wclk), .wrst_n(wrst_n), .rptr(rptr), .wq2_rptr(wq2_rptr));

  sync_w2r #(.ADDR_WIDTH(ADDR_WIDTH)) u_sync_w2r (
    .rclk(rclk), .rrst_n(rrst_n), .wptr(wptr), .rq2_wptr(rq2_wptr));

  fifomem #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) u_fifomem (
    .wclk(wclk), .winc(winc), .wfull(wfull),
    .waddr(waddr), .raddr(raddr), .wdata(wdata), .rdata(rdata));

  wptr_full #(.ADDR_WIDTH(ADDR_WIDTH)) u_wptr_full (
    .wclk(wclk), .wrst_n(wrst_n), .winc(winc), .wq2_rptr(wq2_rptr),
    .wfull(wfull), .waddr(waddr), .wptr(wptr));

  rptr_empty #(.ADDR_WIDTH(ADDR_WIDTH)) u_rptr_empty (
    .rclk(rclk), .rrst_n(rrst_n), .rinc(rinc), .rq2_wptr(rq2_wptr),
    .rempty(rempty), .raddr(raddr), .rptr(rptr));
endmodule