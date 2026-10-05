`ifndef QSPI_SLAVE_SEQUENCER_SV
`define QSPI_SLAVE_SEQUENCER_SV

class qspi_slave_sequencer extends uvm_sequencer #(qspi_seq_item);

  `uvm_component_utils(qspi_slave_sequencer)

  function new(string name = "qspi_slave_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

endclass : qspi_slave_sequencer

`endif 
