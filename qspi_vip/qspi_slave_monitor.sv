class qspi_slave_monitor extends uvm_monitor;

  `uvm_component_utils(qspi_slave_monitor)

  virtual qspi_if   vif;
  qspi_slave_config cfg;

  uvm_analysis_port #(qspi_seq_item) mon_ap;

  bit in_continuous_mode = 1'b0;

  function new(string name = "qspi_slave_monitor", uvm_component parent = null);
    super.new(name, parent);
    mon_ap = new("mon_ap", this);
  endfunction 

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(qspi_slave_config)::get(this, "", "qspi_slave_config", cfg))
    begin
      `uvm_fatal(get_type_name(), "Config getting failed: qspi_slave_config 'cfg' not found in config_db")
    end
    vif = cfg.vif;
  endfunction

  virtual task run_phase(uvm_phase phase);
    in_continuous_mode = 1'b0;

    forever 
    begin
         wait(vif.ce_n === 1'b0);

       fork
        begin : proc_mon
          collect_transaction();
        end
        begin : proc_cs_deassert
          @(posedge vif.ce_n);
        end
      join_any
      disable fork;

       wait(vif.ce_n === 1'b1);
    end
  endtask 

  virtual task collect_transaction();
    qspi_seq_item item;
    bit [7:0]     cmd_byte;
    bit [23:0]    addr_val;
    bit [7:0]     mode_byte;

    item = qspi_seq_item::type_id::create("item");
    item.line_size = cfg.line_size;

    //  Command Phase: 8 SCK 
    if (!in_continuous_mode) 
    begin
      for (int i = 7; i >= 0; i--)
      begin
        @(posedge vif.sck);
        cmd_byte[i] = vif.sio[0];
      end
      item.cmd = cmd_byte;

      // Software Reset commands 
      if (cmd_byte == `QSPI_CMD_RESET_EXEC)
      begin
        item.trans_type = QSPI_TRANS_RESET;
        in_continuous_mode = 1'b0;
        @(posedge vif.ce_n);
        mon_ap.write(item);
      end
      else if (cmd_byte == `QSPI_CMD_RESET_ENABLE) 
      begin
        item.trans_type = QSPI_TRANS_RESET;
        @(posedge vif.ce_n);
        mon_ap.write(item);
      end
      else 
      begin
        item.trans_type = QSPI_TRANS_READ_FIRST;
      end
    end
    else 
    begin
      item.trans_type = QSPI_TRANS_READ_CONT;
      item.cmd        = `QSPI_CMD_FAST_READ_QIO;
    end

     if (item.trans_type != QSPI_TRANS_RESET)
     begin
      for (int i = 5; i >= 0; i--) 
      begin
        @(posedge vif.sck);
        addr_val[i*4 +: 4] = vif.sio[3:0];
      end
      item.addr = addr_val;

      for (int i = 1; i >= 0; i--)
      begin
        @(posedge vif.sck);
        mode_byte[i*4 +: 4] = vif.sio[3:0];
      end
      item.mode = mode_byte;

      in_continuous_mode = (mode_byte == `QSPI_MODE_CONTINUOUS && cfg.continuous_mode_enabled);

      repeat (cfg.dummy_cycles)
     begin
        @(posedge vif.sck);
      end

      item.data = new[cfg.line_size];
      for (int b = 0; b < cfg.line_size; b++) 
      begin
        bit [7:0] d;
        @(posedge vif.sck);
        d[7:4] = vif.sio[3:0];

        @(posedge vif.sck);
        d[3:0] = vif.sio[3:0];

        item.data[b] = d;
      end

      @(posedge vif.ce_n);
      `uvm_info(get_type_name(), $sformatf("Monitored QSPI transfer: %s", item.convert2string()), UVM_MEDIUM)
      mon_ap.write(item);
    end
  endtask
  
endclass 
