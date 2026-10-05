//----------------------------------------------------------------------
// QSPI XiP Flash Controller & AHB-Lite Master VIP Filelist
// Relative to sim/ directory
//----------------------------------------------------------------------

// Include directories
+incdir+../ahb_vip
+incdir+../qspi_vip
+incdir+../rtl
+incdir+../tb
+incdir+../test

// RTL Source Files
../rtl/DMC.v
../rtl/EF_QSPI_XIP_CTRL.v
../rtl/EF_QSPI_XIP_CTRL_AHBL.v

// AHB-Lite VIP Packages and Interfaces
../ahb_vip/ahb_types_pkg.sv
../ahb_vip/ahb_assertions.sv
../ahb_vip/ahb_lite_if.sv
../ahb_vip/ahb_master_pkg.sv

// QSPI VIP Interface and Package
../qspi_vip/qspi_if.sv
../qspi_vip/qspi_pkg.sv

// Testbench Environment Package
../tb/tb_pkg.sv

// Test Library Package
../test/test_pkg.sv

// Top-Level Testbench
../tb/tb_top.sv
