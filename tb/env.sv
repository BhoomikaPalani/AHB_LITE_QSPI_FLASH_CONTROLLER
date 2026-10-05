class qspi_env extends uvm_env;

  `uvm_component_utils(qspi_env)

  qspi_env_config      cfg;

  ahb_master_agent     ahb_m_agent;
  qspi_slave_agent     qspi_s_agent;

  qspi_scoreboard      scb;

  function new(string name = "qspi_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(qspi_env_config)::get(this, "", "qspi_env_config", cfg)) begin
      `uvm_warning("NOCFG", "qspi_env_config not found in db, creating default")
      cfg = qspi_env_config::type_id::create("cfg");
    end

    uvm_config_db#(ahb_master_config)::set(this, "ahb_m_agent*", "ahb_master_config", cfg.ahb_cfg);
    uvm_config_db#(qspi_slave_config)::set(this, "qspi_s_agent*", "qspi_slave_config", cfg.qspi_cfg);

    
    ahb_m_agent  = ahb_master_agent::type_id::create("ahb_m_agent", this);
    qspi_s_agent = qspi_slave_agent::type_id::create("qspi_s_agent", this);

    if (cfg.has_scoreboard) 
    begin
      scb = qspi_scoreboard::type_id::create("scb", this);
      scb.ref_mem = cfg.ref_mem;
    end
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.has_scoreboard)
    begin
           ahb_m_agent.mon_ap.connect(scb.ahb_export);
           qspi_s_agent.mon_ap.connect(scb.qspi_export);
    end
  endfunction
  
endclass

