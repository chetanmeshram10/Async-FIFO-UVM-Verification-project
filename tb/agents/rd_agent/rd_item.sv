class rd_item extends uvm_sequence_item;
  rand int unsigned delay;   // idle cycles before this read
  bit [7:0]         data;    // filled in by the monitor, not randomized

  constraint c_delay { delay dist {0 := 50, [1:4] :/ 35, [5:12] :/ 15}; }

  `uvm_object_utils(rd_item)

  function new(string name = "rd_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("data=0x%02h delay=%0d", data, delay);
  endfunction
endclass