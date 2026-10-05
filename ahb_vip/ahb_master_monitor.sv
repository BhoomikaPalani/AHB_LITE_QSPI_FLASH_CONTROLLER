class ahb_master_monitor extends uvm_monitor;

  `uvm_component_utils(ahb_master_monitor)

  virtual ahb_lite_if vif;
  ahb_master_config   cfg;

    uvm_analysis_port #(ahb_master_seq_item) mon_ap;

  function new(string name = "ahb_master_monitor", uvm_component parent = null);
    super.new(name, parent);
    mon_ap = new("mon_ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(ahb_master_config)::get(this, "", "ahb_master_config", cfg))
    begin
      `uvm_fatal(get_type_name(), "Config getting failed: ahb_master_config 'cfg' not found in config_db")
    end
    vif = cfg.vif;
  endfunction 

  virtual task run_phase(uvm_phase phase);
    ahb_master_seq_item trans = null;
    int beat_idx    = 0;
    int total_beats = 0;

    wait(vif.HRESETn === 1'b1);
    @(posedge vif.HCLK);

    forever
    begin
      @(posedge vif.HCLK);

        if (!vif.HRESETn)
       	begin
        	trans = null;
        	beat_idx = 0;
        	total_beats = 0;
      	end
        else if (vif.cb_mon.HREADY)
       	begin
             // --- DATA PHASE----------------------------       
	  if (trans != null)
	  begin
          	if (trans.hwrite == AHB_WRITE)
	       	begin
            	trans.hwdata[beat_idx] = vif.cb_mon.HWDATA;
          	end 
		else
	       	begin
            	trans.hrdata[beat_idx] = vif.cb_mon.HRDATA;
          	end
          	//trans.hresp[beat_idx] = hresp_e'(vif.cb_mon.HRESP);

          `uvm_info(get_type_name(), $sformatf("[AHB_MON] Data Phase Beat %0d/%0d Complete: DATA=0x%08h",beat_idx, total_beats,(trans.hwrite == AHB_WRITE) ? trans.hwdata[beat_idx] : trans.hrdata[beat_idx],), UVM_LOW)

          	beat_idx++;

                    if (beat_idx == total_beats || vif.cb_mon.HRESP == HRESP_ERROR) 
		    begin
            		`uvm_info(get_type_name(), $sformatf("[AHB_MON] Burst Completed: ADDR=0x%08h %s Beats=%0d -> Writing to Scoreboard",trans.haddr, trans.hwrite.name(), total_beats), UVM_LOW)

            mon_ap.write(trans);
            trans       = null;
            beat_idx    = 0;
            total_beats = 0;
          end
        end

        // ------------ ADDRESS PHASE---------------------
        if (vif.cb_mon.HTRANS == HTRANS_NONSEQ)
       	begin
          trans = ahb_master_seq_item::type_id::create("trans");
          trans.haddr     = vif.cb_mon.HADDR;
          trans.htrans    = htrans_e'(vif.cb_mon.HTRANS);
          trans.hwrite    = hwrite_e'(vif.cb_mon.HWRITE);
          trans.hsize     = hsize_e'(vif.cb_mon.HSIZE);
          trans.hburst    = hburst_e'(vif.cb_mon.HBURST);
          trans.hprot     = vif.cb_mon.HPROT;
          trans.hmastlock = vif.cb_mon.HMASTLOCK;
          total_beats     = ahb_types_pkg::get_burst_beats(trans.hburst);
          trans.hwdata    = new[total_beats];
          trans.hrdata    = new[total_beats];
          trans.hresp     = new[total_beats];
          beat_idx        = 0;

          `uvm_info(get_type_name(), $sformatf("[AHB_MON] New Burst Sampled: ADDR=0x%08h %s %s Beats=%0d",
                    trans.haddr, trans.hwrite.name(), trans.hburst.name(), total_beats), UVM_LOW)
        end

      end
    end
  endtask

endclass 
