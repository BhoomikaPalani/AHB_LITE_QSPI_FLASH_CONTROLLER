class base_test extends uvm_test;

  `uvm_component_utils(base_test)

  qspi_env  env;
  qspi_env_config cfg;

  function new(string name = "base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

       cfg = qspi_env_config::type_id::create("cfg");

     if (!uvm_config_db#(virtual ahb_lite_if)::get(this, "", "ahb_vif", cfg.ahb_cfg.vif))
     begin
      `uvm_fatal("NO_VIF", "Could not get ahb_vif from uvm_config_db!")
    end

    if (!uvm_config_db#(virtual qspi_if)::get(this, "", "qspi_vif", cfg.qspi_cfg.vif))
    begin
      `uvm_fatal("NO_VIF", "Could not get qspi_vif from uvm_config_db!")
    end

    configure_memory();

       uvm_config_db#(qspi_env_config)::set(this, "env", "qspi_env_config", cfg);

       env = qspi_env::type_id::create("env", this);
  endfunction

   virtual function void configure_memory();
    `uvm_info(get_type_name(), "Pre-loading flash memory with random content", UVM_LOW)
    cfg.ref_mem.load_random(131072); // 128 KB -> num_bytes
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction 

  virtual task run_phase(uvm_phase phase);
    seq_base_single_read  seq;
    
    phase.raise_objection(this);

    `uvm_info(get_type_name(), "Starting default base_single_read sequence", UVM_LOW)
    seq = seq_base_single_read::type_id::create("seq");
    seq.start(env.ahb_m_agent.sequencer);

    #500ns;
    phase.drop_objection(this);
  endtask

endclass

