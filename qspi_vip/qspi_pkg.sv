`ifndef QSPI_PKG_SV
`define QSPI_PKG_SV

`include "qspi_defines.svh"

package qspi_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "qspi_seq_item.sv"
  `include "qspi_memory_model.sv"
  `include "qspi_slave_config.sv"
  `include "qspi_slave_sequencer.sv"
  `include "qspi_slave_driver.sv"
  `include "qspi_slave_monitor.sv"
  `include "qspi_slave_agent.sv"

endpackage : qspi_pkg

`endif 
