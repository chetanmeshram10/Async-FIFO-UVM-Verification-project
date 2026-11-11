module fifomem #(
  parameter DATA_WIDTH = 8,
  parameter ADDR_WIDTH = 4
)(
  input  logic                  wclk,
  input  logic                  winc,
  input  logic                  wfull,
  input  logic [ADDR_WIDTH-1:0] waddr,
  input  logic [ADDR_WIDTH-1:0] raddr,
  input  logic [DATA_WIDTH-1:0] wdata,
  output logic [DATA_WIDTH-1:0] rdata
);
  localparam DEPTH = 1 << ADDR_WIDTH;
  logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  assign rdata = mem[raddr];

`ifdef BUG_3
  // BUG_3: write accepted even when full (overflow)
  always_ff @(posedge wclk) if (winc) mem[waddr] <= wdata;
`else
  always_ff @(posedge wclk) if (winc && !wfull) mem[waddr] <= wdata;
`endif
endmodule