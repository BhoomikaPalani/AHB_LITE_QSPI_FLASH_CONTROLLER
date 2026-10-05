`ifndef QSPI_SLAVE_CONFIG_SV
`define QSPI_SLAVE_CONFIG_SV

class qspi_slave_config extends uvm_object;

  uvm_active_passive_enum is_active                = UVM_ACTIVE;
  int unsigned            line_size                = `QSPI_DEFAULT_LINE_SIZE;
  int unsigned            dummy_cycles             = 4;
  bit                     continuous_mode_enabled  = 1'b1;

  // Shared Memory Model handle
  qspi_memory_model       mem;

  // Virtual interface handle
  virtual qspi_if         vif;

  `uvm_object_utils_begin(qspi_slave_config)
    `uvm_field_enum(uvm_active_passive_enum, is_active,              UVM_ALL_ON)
    `uvm_field_int(line_size,                                        UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(dummy_cycles,                                     UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(continuous_mode_enabled,                          UVM_ALL_ON | UVM_BIN)
  `uvm_object_utils_end

  function new(string name = "qspi_slave_config");
    super.new(name);
    mem = qspi_memory_model::type_id::create("mem");
  endfunction : new

endclass : qspi_slave_config

`endif 
