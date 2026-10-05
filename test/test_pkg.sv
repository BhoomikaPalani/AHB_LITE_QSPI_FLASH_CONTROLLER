`include "ahb_defines.svh"
`include "qspi_defines.svh"

package test_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import ahb_types_pkg::*;
  import ahb_master_pkg::*;
  import qspi_pkg::*;
  import tb_pkg::*;

  `include "controller_seq_lib.sv"
  `include "base_test.sv"
  `include "test_lib.sv"

endpackage



