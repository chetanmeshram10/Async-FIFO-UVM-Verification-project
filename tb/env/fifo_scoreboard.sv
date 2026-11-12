`uvm_analysis_imp_decl(_wr)
`uvm_analysis_imp_decl(_rd)

class fifo_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(fifo_scoreboard)

  uvm_analysis_imp_wr #(wr_item, fifo_scoreboard) wr_export;
  uvm_analysis_imp_rd #(rd_item, fifo_scoreboard) rd_export;

  int unsigned depth = 16;            // 2**ADDR_WIDTH
  bit          expect_empty_at_end = 1;

  bit [7:0]    model[$];              // reference model: the FIFO contents
  int unsigned n_wr, n_rd, n_match, n_mismatch, n_underflow, n_overflow;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    wr_export = new("wr_export", this);
    rd_export = new("rd_export", this);
  endfunction

  // an accepted write was observed
  function void write_wr(wr_item t);
    if (model.size() >= depth) begin
      n_overflow++;
      `uvm_error("SB_OVERFLOW",
        $sformatf("Write 0x%02h accepted while model is full (%0d entries)", t.data, model.size()))
      return;
    end
    model.push_back(t.data);
    n_wr++;
  endfunction

  // an accepted read was observed
  function void write_rd(rd_item t);
    bit [7:0] exp;
    n_rd++;
    if (model.size() == 0) begin
      n_underflow++;
      `uvm_error("SB_UNDERFLOW",
        $sformatf("Read 0x%02h accepted but model is empty", t.data))
      return;
    end
    exp = model.pop_front();
    if (t.data !== exp) begin
      n_mismatch++;
      `uvm_error("SB_MISMATCH",
        $sformatf("Read data 0x%02h, expected 0x%02h", t.data, exp))
    end else begin
      n_match++;
    end
  endfunction

  function void check_phase(uvm_phase phase);
    if (n_wr == 0)
      `uvm_error("SB_NOTRAFFIC", "No writes observed: testbench did not exercise the DUT")
    if (expect_empty_at_end && model.size() != 0)
      `uvm_error("SB_LEFTOVER",
        $sformatf("%0d entries written but never read", model.size()))
  endfunction

  function void report_phase(uvm_phase phase);
    uvm_report_server srv = uvm_report_server::get_server();
    int unsigned errs = srv.get_severity_count(UVM_ERROR) + srv.get_severity_count(UVM_FATAL);
    `uvm_info("SB", $sformatf(
      "writes=%0d reads=%0d match=%0d mismatch=%0d underflow=%0d overflow=%0d leftover=%0d",
      n_wr, n_rd, n_match, n_mismatch, n_underflow, n_overflow, model.size()), UVM_LOW)
    if (errs == 0) `uvm_info("SB_RESULT", "*** TEST PASSED ***", UVM_LOW)
    else           `uvm_info("SB_RESULT", "*** TEST FAILED ***", UVM_LOW)
  endfunction
endclass