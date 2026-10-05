AHB-Lite QSPI XiP Flash Controller Verification

SystemVerilog and UVM-based verification environment for an AHB-Lite QSPI Execute-in-Place (XiP) Flash Controller with a direct-mapped cache.

Overview

<img width="457" height="318" alt="overblock" src="https://github.com/user-attachments/assets/61fb56bd-1841-4e72-a18d-6f9d8d7e4c52" />



The DUT is an AHB-Lite based QSPI XiP Flash Controller that provides access to external QSPI flash memory through an AHB-Lite interface.

The controller includes a 512-byte direct-mapped cache, organized as 16 cache lines of 32 bytes each. On an AHB-Lite read, the controller checks the cache first. On a cache miss, it fetches the required cache line from QSPI flash and stores it in the cache before returning the requested data.

The main focus of this project is the development of custom AHB-Lite and QSPI UVM VIPs and functional verification of the DUT.

Verification Architecture
                   <img width="688" height="515" alt="tb" src="https://github.com/user-attachments/assets/87fe84dd-93b5-4941-8271-667c8eb20bae" />


The AHB-Lite Master VIP generates transactions to the DUT.

The DUT generates QSPI transactions to access the external flash. The QSPI Reactive Slave VIP responds to these transactions using the flash memory model.

The monitored transactions are provided to the scoreboard for functional checking.

AHB-Lite VIP Development

A custom UVM-based AHB-Lite Master VIP was developed to generate and monitor AHB-Lite transactions.

AHB-Lite VIP Components
ahb_vip/
|
|-- ahb_lite_if.sv
|-- ahb_master_seq_item.sv
|-- ahb_master_config.sv
|-- ahb_master_driver.sv
|-- ahb_master_monitor.sv
|-- ahb_master_sequencer.sv
|-- ahb_master_agent.sv
|-- ahb_master_seq_lib.sv
|-- ahb_master_pkg.sv
|-- ahb_types_pkg.sv
`-- ahb_assertions.sv
Features
AHB-Lite transaction generation
Read transaction support
Pipelined transaction support
Burst transaction support
AHB-Lite protocol monitoring
Protocol assertions
Configurable UVM Master Agent
Reusable sequence library
QSPI VIP Development

A custom UVM-based Reactive QSPI Slave VIP was developed to model the external QSPI flash connected to the DUT.

Since the DUT initiates QSPI transactions, the QSPI VIP operates as a reactive slave.

QSPI VIP Components
qspi_vip/
|
|-- qspi_if.sv
|-- qspi_seq_item.sv
|-- qspi_slave_config.sv
|-- qspi_slave_driver.sv
|-- qspi_slave_monitor.sv
|-- qspi_slave_sequencer.sv
|-- qspi_slave_agent.sv
|-- qspi_memory_model.sv
`-- qspi_pkg.sv
Features
Reactive QSPI slave operation
QSPI read response generation
Flash memory modeling
QSPI transaction monitoring
Configurable QSPI Slave Agent
Integration with the DUT
DUT Verification

The DUT is verified using the following flow:

AHB Master VIP
      |
      v
   AHB-Lite
      |
      v
     DUT
      |
      v
     QSPI
      |
      v
QSPI Slave VIP
      |
      v
Flash Memory Model
      |
      v
     DUT
      |
      v
AHB Response
      |
      v
 Scoreboard

The verification environment checks the complete transaction path from the AHB-Lite request to the final returned data.

Both cache-hit and cache-miss operations are verified.

Cache
Parameter	Value
Cache Size	512 bytes
Cache Type	Direct Mapped
Number of Lines	16
Line Size	32 bytes
Data Width	32 bits

The verification focuses on cache hits, cache misses, cache-line refill, repeated accesses, and cache-line boundary conditions.


Project Structure

AHB_LITE_QSPI_FLASH_CONTROLLER/
|
|-- ahb_vip/                  # AHB-Lite Master VIP
|
|-- qspi_vip/                 # Reactive QSPI Slave VIP
|
|-- rtl/                      # Design Under Verification
|   |-- EF_QSPI_XIP_CTRL_AHBL.v
|   |-- EF_QSPI_XIP_CTRL.v
|   `-- DMC.v
|
|-- tb/                       # UVM Testbench
|   |-- tb_top.sv
|   |-- tb_pkg.sv
|   |-- env.sv
|   |-- env_config.sv
|   `-- scoreboard.sv
|
|-- test/                     # UVM Tests and Sequences
|   |-- base_test.sv
|   |-- controller_seq_lib.sv
|   |-- test_lib.sv
|   `-- test_pkg.sv
|
|-- sim/                      # Simulation
|   |-- Makefile
|   |-- filelist.f
|
|-- .gitignore
`-- README.md



Author
Bhoomika Palani
