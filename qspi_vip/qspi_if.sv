`ifndef QSPI_IF_SV
`define QSPI_IF_SV

`include "qspi_defines.svh"

interface qspi_if (
  input logic HCLK,
  input logic HRESETn
);

  // Physical QSPI signals
  logic       sck;
  logic       ce_n;
  wire  [3:0] sio;

  // VIP Driver internal signals for tri-state driving
  logic [3:0] drv_data;
  logic       drv_en;

  // Drive SIO when VIP driver asserts drv_en
  assign sio = drv_en ? drv_data : 4'bz;

  // Modports
  modport slave_driver_mp (
    input  HCLK,
    input  HRESETn,
    input  sck,
    input  ce_n,
    inout  sio,
    output drv_data,
    output drv_en
  );

  modport slave_monitor_mp (
    input  HCLK,
    input  HRESETn,
    input  sck,
    input  ce_n,
    input  sio
  );

endinterface : qspi_if

`endif 
