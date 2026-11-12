class wr_item extends uvm_sequence_item;
  rand bit [7:0]      data;
  rand int unsigned   delay;   // idle cycles before this write

  constraint c_delay { delay dist {0 := 60, [1:3] :/ 30, [4:10] :/ 10}; }

  `uvm_object_utils(wr_item)

  function new(string name = "wr_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("data=0x%02h delay=%0d", data, delay);
  endfunction
endclass