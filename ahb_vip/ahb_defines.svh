// Bus Width Configuration
`define AHB_ADDR_WIDTH       32
`define AHB_DATA_WIDTH       32
`define AHB_PROT_WIDTH       4
`define AHB_BURST_WIDTH      3
`define AHB_SIZE_WIDTH       3
`define AHB_TRANS_WIDTH      2
`define AHB_RESP_WIDTH       1

// 1KB Boundary Mask (Address bits [9:0] must not overflow across beats)
`define AHB_1KB_BOUNDARY_MASK 32'h0000_03FF

// Default Reset Values
`define AHB_DEFAULT_ADDR     32'h0000_0000
`define AHB_DEFAULT_DATA     32'h0000_0000

// Time Resolution for Interfaces
`define AHB_TIME_UNIT        1ns
`define AHB_TIME_PRECISION   1ps

