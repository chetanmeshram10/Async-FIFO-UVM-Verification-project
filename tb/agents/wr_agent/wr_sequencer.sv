class wr_sequencer extends uvm_sequencer #(wr_item);
  `uvm_component_utils(wr_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass