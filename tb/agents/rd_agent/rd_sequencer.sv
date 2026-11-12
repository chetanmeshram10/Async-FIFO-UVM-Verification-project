class rd_sequencer extends uvm_sequencer #(rd_item);
  `uvm_component_utils(rd_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass