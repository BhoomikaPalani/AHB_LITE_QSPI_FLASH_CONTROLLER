class ahb_master_driver extends uvm_driver #(ahb_master_seq_item);

  `uvm_component_utils(ahb_master_driver)

  virtual ahb_lite_if vif;
  ahb_master_config   cfg;


  ahb_master_seq_item pipeline[$];
  ahb_master_seq_item pending_req = null;

  uvm_phase phase_h;

  function new(string name = "ahb_master_driver",uvm_component parent = null);
    super.new(name,parent);
  endfunction 

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(ahb_master_config)::get(this,"","ahb_master_config",cfg))
    begin
      `uvm_fatal("NO_CFG", "ahb_master get() config failed")
    end
  endfunction 

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    vif = cfg.vif;
  endfunction 

  virtual task run_phase(uvm_phase phase);
    phase_h = phase;
    reset_bus();

    wait(vif.HRESETn === 1'b1);
    repeat (2) @(vif.cb_master);

    forever begin
      fork
        begin : pipeline_thread
          fork
            address_phase();
            data_phase();
          join
        end

        begin : mid_reset_thread
          @(negedge vif.HRESETn);
          `uvm_info(get_type_name(), "[AHB_DRV] Reset detected! Resetting bus.", UVM_LOW)
          reset_bus();
          wait(vif.HRESETn === 1'b1);
          repeat (2) @(vif.cb_master);
        end
      join_any
      disable fork;
    end
  endtask 

  virtual task reset_bus();
    vif.cb_master.HADDR     <= `AHB_DEFAULT_ADDR;
    vif.cb_master.HTRANS    <= HTRANS_IDLE;
    vif.cb_master.HWRITE    <= AHB_READ;
    vif.cb_master.HSIZE     <= HSIZE_32BIT;
    vif.cb_master.HBURST    <= HBURST_SINGLE;
    vif.cb_master.HPROT     <= 4'b0011;
    vif.cb_master.HMASTLOCK <= 1'b0;
    vif.cb_master.HWDATA    <= `AHB_DEFAULT_DATA;
    //pipeline.delete();
  endtask 

  virtual task address_phase();
    ahb_master_seq_item xtn;
    int beats;
    logic [`AHB_ADDR_WIDTH-1:0] addr;

    forever 
    begin
      if (pending_req == null)
      begin
        seq_item_port.get_next_item(req);
        pending_req = req;
      end
      xtn = pending_req;

      beats = ahb_types_pkg::get_burst_beats(xtn.hburst);
      addr  = xtn.haddr;

      while (!vif.cb_master.HREADY)
      begin
        @(vif.cb_master);
      end

      for (int b = 0; b < beats; b++)
      begin
            if (b > 0)
	    begin
         	 addr = ahb_types_pkg::calculate_next_addr(addr, xtn.hburst, xtn.hsize);
          	vif.cb_master.HTRANS <= HTRANS_SEQ;
            end 
	    else 
	    begin
          	vif.cb_master.HTRANS <= HTRANS_NONSEQ;
            end

        vif.cb_master.HADDR     <= addr;
        vif.cb_master.HBURST    <= xtn.hburst;
        vif.cb_master.HSIZE     <= xtn.hsize;
        vif.cb_master.HWRITE    <= xtn.hwrite;
        vif.cb_master.HPROT     <= xtn.hprot;
        vif.cb_master.HMASTLOCK <= xtn.hmastlock;

        `uvm_info(get_type_name(), $sformatf("[AHB_DRV_ADDR] Driving Beat %0d/%0d: %s ADDR=0x%08h | HTRANS=%s",b, beats, xtn.hwrite.name(), addr, (b == 0) ? "NONSEQ" : "SEQ"), UVM_LOW)

        do @(vif.cb_master);
        while (!vif.cb_master.HREADY);

        pipeline.push_back(xtn);
      end

      seq_item_port.item_done();
      pending_req = null;

      vif.cb_master.HTRANS <= HTRANS_IDLE;
    end
  endtask 

  virtual task data_phase();
    ahb_master_seq_item xtn;
    int beat_idx = 0;
    int beats    = 0;

    forever begin
      wait(pipeline.size() > 0);
      xtn = pipeline.pop_front();
      beats = ahb_types_pkg::get_burst_beats(xtn.hburst);

      phase_h.raise_objection(this);

      if (xtn.hwrite == AHB_WRITE)
      begin
        vif.cb_master.HWDATA <= xtn.hwdata[beat_idx];
      end

      do @(vif.cb_master);
      while (!vif.cb_master.HREADY);

      if (xtn.hwrite == AHB_READ)
      begin
        xtn.hrdata[beat_idx] = vif.cb_master.HRDATA;
      end
      //xtn.hresp[beat_idx] = hresp_e'(vif.cb_master.HRESP);

       `uvm_info(get_type_name(), $sformatf("[AHB_DRV_DATA] Completed Beat %0d/%0d: ADDR=0x%08h DATA=0x%08h HRESP=%s",
                beat_idx, beats, xtn.get_beat_addr(beat_idx),
                (xtn.hwrite == AHB_WRITE) ? xtn.hwdata[beat_idx] : xtn.hrdata[beat_idx],
                xtn.hresp[beat_idx].name()), UVM_LOW)
      beat_idx++;
      if (beat_idx == beats) 
      begin
        beat_idx = 0;
      end

      phase_h.drop_objection(this);
    end
  endtask 

endclass 
