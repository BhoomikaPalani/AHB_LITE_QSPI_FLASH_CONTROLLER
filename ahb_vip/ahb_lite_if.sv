`include "ahb_defines.svh"
import ahb_types_pkg::*;

interface ahb_lite_if (
  input logic HCLK,
  input logic HRESETn
);

  logic [`AHB_ADDR_WIDTH-1:0]  HADDR;
  logic [`AHB_BURST_WIDTH-1:0] HBURST;
  logic                        HMASTLOCK;
  logic [`AHB_PROT_WIDTH-1:0]  HPROT;
  logic [`AHB_SIZE_WIDTH-1:0]  HSIZE;
  logic [`AHB_TRANS_WIDTH-1:0] HTRANS;
  logic [`AHB_DATA_WIDTH-1:0]  HWDATA;
  logic                        HWRITE;

  logic                        HSEL;
  wire [`AHB_DATA_WIDTH-1:0]   HRDATA;
  wire                         HREADY;     // Global bus ready input to slave/master
  wire                         HREADYOUT;  // Slave ready output
  wire [`AHB_RESP_WIDTH-1:0]   HRESP;

  clocking cb_master @(posedge HCLK);
    default input #1step output #1ns;
    input  HRESETn;
    input  HRDATA;
    input  HREADY;
    input  HRESP;
    output HADDR;
    output HBURST;
    output HMASTLOCK;
    output HPROT;
    output HSIZE;
    output HTRANS;
    output HWDATA;
    output HWRITE;
  endclocking : cb_master

  clocking cb_slave @(posedge HCLK);
    default input #1step output #1ns;
    input  HRESETn;
    input  HSEL;
    input  HADDR;
    input  HBURST;
    input  HMASTLOCK;
    input  HPROT;
    input  HSIZE;
    input  HTRANS;
    input  HWDATA;
    input  HWRITE;
    input  HREADY;
    input  HRDATA;
    input  HREADYOUT;
    input  HRESP;
  endclocking : cb_slave

   clocking cb_mon @(posedge HCLK);
    default input #1step;
    input HRESETn;
    input HSEL;
    input HADDR;
    input HBURST;
    input HMASTLOCK;
    input HPROT;
    input HSIZE;
    input HTRANS;
    input HWDATA;
    input HWRITE;
    input HRDATA;
    input HREADY;
    input HREADYOUT;
    input HRESP;
  endclocking : cb_mon

   modport master_mp (
    clocking cb_master,
    input    HCLK,
    input    HRESETn
  );

  modport slave_mp (
    clocking cb_slave,
    input    HCLK,
    input    HRESETn
  );

  modport monitor_mp (
    clocking cb_mon,
    input    HCLK,
    input    HRESETn
  );

  modport raw_master_mp (
    input  HCLK, HRESETn, HRDATA, HREADY, HRESP,
    output HADDR, HBURST, HMASTLOCK, HPROT, HSIZE, HTRANS, HWDATA, HWRITE
  );

  modport raw_slave_mp (
    input  HCLK, HRESETn, HSEL, HADDR, HBURST, HMASTLOCK, HPROT, HSIZE, HTRANS, HWDATA, HWRITE, HREADY,
    output HRDATA, HREADYOUT, HRESP
  );

endinterface 
