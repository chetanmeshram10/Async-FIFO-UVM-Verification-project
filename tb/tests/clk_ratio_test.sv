class clk_ratio_test extends random_test;
  `uvm_component_utils(clk_ratio_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    num_items = 500;
  endfunction
endclass