`uvm_analysis_imp_decl(_cwr)
`uvm_analysis_imp_decl(_crd)

class fifo_coverage extends uvm_component;
  `uvm_component_utils(fifo_coverage)

  uvm_analysis_imp_cwr #(wr_item, fifo_coverage) wr_export;
  uvm_analysis_imp_crd #(rd_item, fifo_coverage) rd_export;

  localparam int DEPTH = 16;
  typedef enum {OP_WR, OP_RD} op_e;
  typedef enum {WR_MUCH_FASTER, WR_FASTER, SIMILAR, RD_FASTER, RD_MUCH_FASTER} ratio_e;

  int     level;                      // occupancy BEFORE the current operation
  op_e    op;
  ratio_e ratio;
  int     wclk_ps = 10000, rclk_ps = 27000;

  covergroup cg_fifo;
    option.per_instance = 1;

    cp_level : coverpoint level {
      bins empty       = {0};
      bins low         = {[1:4]};
      bins mid         = {[5:11]};
      bins almost_full = {[12:15]};
      bins full        = {DEPTH};
    }
    cp_op : coverpoint op;
    cp_trans : coverpoint level {
      bins empty_to_one    = (0  => 1);
      bins one_to_empty    = (1  => 0);
      bins fifteen_to_full = (15 => 16);
      bins full_to_fifteen = (16 => 15);
    }
    cp_ratio : coverpoint ratio;

    x_level_op : cross cp_level, cp_op {
      ignore_bins no_wr_when_full  = binsof(cp_level.full)  && binsof(cp_op) intersect {OP_WR};
      ignore_bins no_rd_when_empty = binsof(cp_level.empty) && binsof(cp_op) intersect {OP_RD};
    }
    x_ratio_level : cross cp_ratio, cp_level;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_fifo = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    wr_export = new("wr_export", this);
    rd_export = new("rd_export", this);
    void'($value$plusargs("WCLK_PS=%d", wclk_ps));
    void'($value$plusargs("RCLK_PS=%d", rclk_ps));
    if      (wclk_ps*4 <= rclk_ps)   ratio = WR_MUCH_FASTER;
    else if (rclk_ps*4 <= wclk_ps)   ratio = RD_MUCH_FASTER;
    else if (wclk_ps*5 <  rclk_ps*4) ratio = WR_FASTER;
    else if (rclk_ps*5 <  wclk_ps*4) ratio = RD_FASTER;
    else                             ratio = SIMILAR;
  endfunction

  function void write_cwr(wr_item t);
    op = OP_WR;  cg_fifo.sample();
    if (level < DEPTH) level++;
  endfunction

  function void write_crd(rd_item t);
    op = OP_RD;  cg_fifo.sample();
    if (level > 0) level--;
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("clock ratio bin = %s", ratio.name()), UVM_LOW)
    `uvm_info("COV", $sformatf("cp_level=%.1f%% cp_trans=%.1f%% x_level_op=%.1f%% cp_ratio=%.1f%% total=%.1f%%",
      cg_fifo.cp_level.get_inst_coverage(),
      cg_fifo.cp_trans.get_inst_coverage(),
      cg_fifo.x_level_op.get_inst_coverage(),
      cg_fifo.cp_ratio.get_inst_coverage(),
      cg_fifo.get_inst_coverage()), UVM_LOW)
  endfunction
endclass