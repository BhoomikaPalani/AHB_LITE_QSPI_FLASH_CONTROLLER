`ifndef QSPI_ENV_CONFIG_SV
`define QSPI_ENV_CONFIG_SV

class qspi_env_config extends uvm_object;

  `uvm_object_utils(qspi_env_config)

  // Sub-VIP configuration handles
  ahb_master_config   ahb_cfg;
  qspi_slave_config   qspi_cfg;

  // Shared Reference Memory Model
  qspi_memory_model   ref_mem;

  // Environment knobs
  bit has_scoreboard = 1'b1;
  bit has_coverage   = 1'b1;

  function new(string name = "qspi_env_config");
    super.new(name);
    // Create shared memory
    ref_mem  = qspi_memory_model::type_id::create("ref_mem");

    // Initialize AHB Master config
    ahb_cfg  = ahb_master_config::type_id::create("ahb_cfg");
    ahb_cfg.is_active = UVM_ACTIVE;

    // Initialize QSPI Slave config with shared memory
    qspi_cfg = qspi_slave_config::type_id::create("qspi_cfg");
    qspi_cfg.is_active = UVM_ACTIVE;
    qspi_cfg.mem       = ref_mem;
  endfunction : new

endclass : qspi_env_config

`endif 
