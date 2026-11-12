class rd_rand_seq extends uvm_sequence #(rd_item);
  `uvm_object_utils(rd_rand_seq)

  int unsigned num_items = 20;

  function new(string name = "rd_rand_seq");
    super.new(name);
  endfunction

  task body();
    repeat (num_items) begin
      req = rd_item::type_id::create("req");
      start_item(req);
      if (!req.randomize()) `uvm_error("RAND", "rd_item randomize failed")
      finish_item(req);
    end
  endtask
endclass