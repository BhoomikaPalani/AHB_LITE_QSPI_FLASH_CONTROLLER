`timescale 1ns/1ps

`include "uvm_macros.svh"
`include "ahb_defines.svh"
`include "qspi_defines.svh"

import uvm_pkg::*;
import ahb_types_pkg::*;
import ahb_master_pkg::*;
import qspi_pkg::*;
import tb_pkg::*;
import test_pkg::*;

module tb_top;

  logic HCLK;
  logic HRESETn;

  // 50 MHz Clock 
   initial
   begin
    	HCLK = 1'b0;
    	forever #10ns HCLK = ~HCLK;
   end

    initial
    begin
    	HRESETn = 1'b0;
    	#100ns;
    	@(posedge HCLK);
   	 HRESETn = 1'b1;
    	`uvm_info("TB_TOP", "HRESETn released HIGH (System Running)", UVM_LOW)
  end

  ahb_lite_if ahb_vif (.HCLK(HCLK),.HRESETn(HRESETn));
  qspi_if qspi_vif (.HCLK(HCLK),.HRESETn(HRESETn));

  wire [3:0] dut_dout;
  wire [3:0] dut_douten;
  wire [3:0] dut_din;

   assign ahb_vif.HSEL   = 1'b1;                
   assign ahb_vif.HREADY = ahb_vif.HREADYOUT;   
   assign ahb_vif.HRESP  = 1'b0;                

    EF_QSPI_XIP_CTRL_AHBL #(.NUM_LINES   (`QSPI_DEFAULT_NUM_LINES), .LINE_SIZE   (`QSPI_DEFAULT_LINE_SIZE), .RESET_CYCLES(25)  ) u_dut (
    .HCLK      (HCLK),
    .HRESETn   (HRESETn),
    .HSEL      (ahb_vif.HSEL),
    .HADDR     (ahb_vif.HADDR),
    .HTRANS    (ahb_vif.HTRANS),
    .HWRITE    (ahb_vif.HWRITE),
    .HREADY    (ahb_vif.HREADY),
    .HREADYOUT (ahb_vif.HREADYOUT),
    .HRDATA    (ahb_vif.HRDATA),
    .sck       (qspi_vif.sck),
    .ce_n      (qspi_vif.ce_n),
    .din       (dut_din),
    .dout      (dut_dout),
    .douten    (dut_douten)
  );

  ahb_assertions u_ahb_assertions (
    .HCLK      (ahb_vif.HCLK),
    .HRESETn   (ahb_vif.HRESETn),
    .HSEL      (ahb_vif.HSEL),
    .HADDR     (ahb_vif.HADDR),
    .HBURST    (ahb_vif.HBURST),
    .HMASTLOCK (ahb_vif.HMASTLOCK),
    .HPROT     (ahb_vif.HPROT),
    .HSIZE     (ahb_vif.HSIZE),
    .HTRANS    (ahb_vif.HTRANS),
    .HWDATA    (ahb_vif.HWDATA),
    .HWRITE    (ahb_vif.HWRITE),
    .HRDATA    (ahb_vif.HRDATA),
    .HREADY    (ahb_vif.HREADY),
    .HREADYOUT (ahb_vif.HREADYOUT),
    .HRESP     (ahb_vif.HRESP)
  );


  assign qspi_vif.sio = dut_douten[0] ? dut_dout : 4'bz;
  assign dut_din = qspi_vif.sio;

  pullup(qspi_vif.sio[0]);
  pullup(qspi_vif.sio[1]);
  pullup(qspi_vif.sio[2]);
  pullup(qspi_vif.sio[3]);

  initial 
  begin 
    uvm_config_db#(virtual ahb_lite_if)::set(null, "*", "ahb_vif", ahb_vif);
    uvm_config_db#(virtual qspi_if)::set(null, "*", "qspi_vif", qspi_vif);

    run_test();
  end

  initial 
  begin
    #500ms;
    `uvm_fatal("TIMEOUT", "Simulation exceeded absolute safety limit of 500ms!")
  end

endmodule : tb_top

