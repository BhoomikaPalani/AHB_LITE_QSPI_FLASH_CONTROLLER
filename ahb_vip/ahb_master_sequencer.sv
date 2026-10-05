class ahb_master_sequencer extends uvm_sequencer #(ahb_master_seq_item);

  `uvm_component_utils(ahb_master_sequencer)

  function new(string name = "ahb_master_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction 

endclass
