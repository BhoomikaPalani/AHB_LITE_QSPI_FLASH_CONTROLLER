`ifndef QSPI_DEFINES_SVH
`define QSPI_DEFINES_SVH

// QSPI Protocol Commands
`define QSPI_CMD_RESET_ENABLE 8'h66
`define QSPI_CMD_RESET_EXEC   8'h99
`define QSPI_CMD_FAST_READ_QIO 8'hEB

// Continuous Read Mode Marker
`define QSPI_MODE_CONTINUOUS  8'hA5

// Default controller configuration
`define QSPI_DEFAULT_LINE_SIZE 32
`define QSPI_DEFAULT_NUM_LINES 16
`define QSPI_ADDR_WIDTH        24
`define QSPI_DATA_WIDTH        4

`endif 
