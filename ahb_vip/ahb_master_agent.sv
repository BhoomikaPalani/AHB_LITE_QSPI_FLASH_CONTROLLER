class ahb_master_agent extends uvm_agent;

  `uvm_component_utils(ahb_master_agent)

   ahb_master_config       cfg;

  ahb_master_driver       driver;
  ahb_master_sequencer    sequencer;
  ahb_master_monitor      monitor;

  uvm_analysis_port #(ahb_master_seq_item) mon_ap;

  function new(string name = "ahb_master_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction 

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(ahb_master_config)::get(this, "", "ahb_master_config", cfg)) 
    begin
      `uvm_info(get_type_name(), "cfg not set from top; creating default cfg", UVM_LOW)
     end

       monitor = ahb_master_monitor::type_id::create("monitor", this);

       if (cfg.is_active == UVM_ACTIVE)
       begin
      sequencer = ahb_master_sequencer::type_id::create("sequencer", this);
      driver    = ahb_master_driver::type_id::create("driver", this);
      end
  endfunction 

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

        mon_ap = monitor.mon_ap;

    if (cfg.is_active == UVM_ACTIVE) 
    begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction 

endclass

 
