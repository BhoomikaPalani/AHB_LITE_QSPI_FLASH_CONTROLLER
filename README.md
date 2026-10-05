# AHB-Lite QSPI XiP Flash Controller Verification

SystemVerilog and UVM-based verification environment for an AHB-Lite QSPI Execute-in-Place (XiP) Flash Controller with a direct-mapped cache.

## Overview

<img width="457" height="318" alt="overblock" src="https://github.com/user-attachments/assets/61fb56bd-1841-4e72-a18d-6f9d8d7e4c52" />

The DUT is an AHB-Lite based QSPI XiP Flash Controller that provides access to external QSPI flash memory through an AHB-Lite interface.

The controller includes a 512-byte direct-mapped cache, organized as 16 cache lines of 32 bytes each. On an AHB-Lite read, the controller checks the cache first. On a cache miss, it fetches the required cache line from QSPI flash and stores it in the cache before returning the requested data.

The main focus of this project is the development of custom AHB-Lite and QSPI UVM VIPs and functional verification of the DUT.

## Verification Architecture

<img width="688" height="515" alt="tb" src="https://github.com/user-attachments/assets/87fe84dd-93b5-4941-8271-667c8eb20bae" />

The AHB-Lite Master VIP generates transactions to the DUT.

The DUT generates QSPI transactions to access the external flash. The QSPI Reactive Slave VIP responds to these transactions using the flash memory model.

The monitored transactions are provided to the scoreboard for functional checking.

## AHB-Lite VIP Development

A custom UVM-based AHB-Lite Master VIP was developed to generate and monitor AHB-Lite transactions.

### AHB-Lite VIP Components

```text
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
