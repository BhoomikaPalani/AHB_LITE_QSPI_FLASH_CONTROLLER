`include "ahb_defines.svh"
`include "qspi_defines.svh"

package tb_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import ahb_types_pkg::*;
  import ahb_master_pkg::*;
  import qspi_pkg::*;

  `include "env_config.sv"
  `include "scoreboard.sv"
  `include "env.sv"

endpackage : tb_pkg

