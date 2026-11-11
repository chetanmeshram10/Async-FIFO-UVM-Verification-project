`timescale 1ns/1ps
module directed_tb;
  localparam DW = 8, AW = 4, DEPTH = 1 << AW;

  logic wclk = 0, rclk = 0, wrst_n = 0, rrst_n = 0;
  logic winc = 0, rinc = 0;
  logic [DW-1:0] wdata = '0;
  wire  [DW-1:0] rdata;
  wire  wfull, rempty;

  async_fifo #(.DATA_WIDTH(DW), .ADDR_WIDTH(AW)) dut (.*);

  always #5    wclk = ~wclk;     // 100 MHz
  always #13.5 rclk = ~rclk;     // ~37 MHz

  // ---------- reference model ----------
  logic [DW-1:0] q[$];
  logic [DW-1:0] exp;
  int errors = 0;

  always @(posedge wclk)
    if (wrst_n && winc && !wfull) q.push_back(wdata);

  always @(posedge rclk)
    if (rrst_n && rinc && !rempty) begin
      if (q.size() == 0) begin
        errors++; $display("[%0t] ERROR: read from empty model", $time);
      end else begin
        exp = q.pop_front();
        if (rdata !== exp) begin
          errors++; $display("[%0t] ERROR: rdata=%0h expected=%0h", $time, rdata, exp);
        end
      end
    end

  // ---------- stimulus (drive on negedge, sample on posedge) ----------
  initial begin
    $dumpfile("dump.vcd"); $dumpvars(0, directed_tb);

    repeat (3) @(posedge wclk); wrst_n = 1;
    repeat (3) @(posedge rclk); rrst_n = 1;

    if (rempty !== 1'b1 || wfull !== 1'b0) begin
      errors++; $display("ERROR: bad reset flag values");
    end

    // 1) Fill: try DEPTH+4 writes, FIFO must stop at DEPTH
    repeat (DEPTH + 4) begin
      @(negedge wclk); winc = 1; wdata = $urandom;
    end
    @(negedge wclk); winc = 0;
    repeat (5) @(posedge wclk);
    if (!wfull)             begin errors++; $display("ERROR: wfull not set after fill"); end
    if (q.size() != DEPTH)  begin errors++; $display("ERROR: stored %0d, expected %0d", q.size(), DEPTH); end

    // 2) Drain: try DEPTH+4 reads
    repeat (DEPTH + 4) begin
      @(negedge rclk); rinc = 1;
    end
    @(negedge rclk); rinc = 0;
    repeat (5) @(posedge wclk);
    if (!rempty)         begin errors++; $display("ERROR: rempty not set after drain"); end
    if (q.size() != 0)   begin errors++; $display("ERROR: %0d items left in model", q.size()); end

    // 3) Random traffic on both sides
    $dumpoff;
    fork
      begin
        repeat (2000) begin @(negedge wclk); winc = $urandom_range(0,1); wdata = $urandom; end
        @(negedge wclk); winc = 0;
      end
      begin
        repeat (2000) begin @(negedge rclk); rinc = $urandom_range(0,1); end
        @(negedge rclk); rinc = 0;
      end
    join

    // 4) Final drain
    repeat (DEPTH + 8) begin @(negedge rclk); rinc = 1; end
    @(negedge rclk); rinc = 0;
    repeat (5) @(posedge rclk);
    if (q.size() != 0) begin errors++; $display("ERROR: %0d items left at end", q.size()); end

    if (errors == 0) $display("DIRECTED TEST PASSED");
    else             $display("DIRECTED TEST FAILED: %0d errors", errors);
    $finish;
  end
endmodule