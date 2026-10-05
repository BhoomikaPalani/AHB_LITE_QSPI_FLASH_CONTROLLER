`ifndef QSPI_SLAVE_AGENT_SV
`define QSPI_SLAVE_AGENT_SV

class qspi_slave_agent extends uvm_agent;

  `uvm_component_utils(qspi_slave_agent)

  qspi_slave_config    cfg;
  qspi_slave_driver    driver;
  qspi_slave_sequencer sequencer;
  qspi_slave_monitor   monitor;

  uvm_analysis_port #(qspi_seq_item) mon_ap;

  function new(string name = "qspi_slave_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(qspi_slave_config)::get(this, "", "qspi_slave_config", cfg)) begin
      cfg = qspi_slave_config::type_id::create("cfg");
    end

    monitor = qspi_slave_monitor::type_id::create("monitor", this);

    if (cfg.is_active == UVM_ACTIVE) begin
      sequencer = qspi_slave_sequencer::type_id::create("sequencer", this);
      driver    = qspi_slave_driver::type_id::create("driver", this);
    end
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mon_ap = monitor.mon_ap;

    if (cfg.is_active == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction : connect_phase

endclass : qspi_slave_agent

`endif 
