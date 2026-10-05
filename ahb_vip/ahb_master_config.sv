class ahb_master_config extends uvm_object;

  uvm_active_passive_enum is_active       = UVM_ACTIVE;
  bit                     coverage_enable = 1'b1;
  bit                     checks_enable   = 1'b1;
  int                     timeout_cycles  = 5000;

    virtual ahb_lite_if     vif;

  `uvm_object_utils_begin(ahb_master_config)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
    `uvm_field_int(coverage_enable,                     UVM_ALL_ON)
    `uvm_field_int(checks_enable,                       UVM_ALL_ON)
    `uvm_field_int(timeout_cycles,                      UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "ahb_master_config");
    super.new(name);
  endfunction 

endclass 
