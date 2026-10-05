class qspi_slave_driver extends uvm_driver #(qspi_seq_item);

  `uvm_component_utils(qspi_slave_driver)

  virtual qspi_if   vif;
  qspi_slave_config cfg;

  bit in_continuous_mode = 1'b0;

  function new(string name = "qspi_slave_driver", uvm_component parent = null);
    super.new(name, parent);
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
    vif.drv_en   <= 1'b0;
    vif.drv_data <= 4'h0;
    in_continuous_mode = 1'b0;

    forever 
    begin
      wait(vif.ce_n === 1'b0);

        fork
        begin : proc_transfer
          drive_transfer();
        end
        begin : proc_cs_deassert
          @(posedge vif.ce_n);
        end
      join_any
      disable fork;

      vif.drv_en   <= 1'b0;
      vif.drv_data <= 4'h0;

      wait(vif.ce_n === 1'b1);
    end
  endtask

  virtual task drive_transfer();
    bit [7:0]  cmd_byte;
    bit [23:0] addr_val;
    bit [7:0]  mode_byte;

    `uvm_info(get_type_name(), "[QSPI_SLV] Detected CE_n assertion (Transaction start)", UVM_LOW)

    if (!in_continuous_mode)
    begin
      cmd_byte = 8'h00;
      for (int i = 7; i >= 0; i--) 
      begin
        @(posedge vif.sck);
        cmd_byte[i] = vif.sio[0];
      end

      `uvm_info(get_type_name(), $sformatf("[QSPI_SLV] Sampled Command: 0x%02h", cmd_byte), UVM_LOW)

        if (cmd_byte == `QSPI_CMD_RESET_EXEC)
       	begin
        `uvm_info(get_type_name(), "[QSPI_SLV] Flash Software Reset Execute (0x99): Resetting flash to power-on state", UVM_LOW)
        in_continuous_mode = 1'b0;
        @(posedge vif.ce_n);
      end
      else if (cmd_byte == `QSPI_CMD_RESET_ENABLE)
      begin
        `uvm_info(get_type_name(), "[QSPI_SLV] Flash Software Reset Enable (0x66) accepted", UVM_LOW)
        @(posedge vif.ce_n);
      end
    end
    else
    begin
      `uvm_info(get_type_name(), "[QSPI_SLV] Continuous Read Mode Active: Opcode phase skipped", UVM_LOW)
    end

    // Address Phase   
    addr_val = 24'h000000;
    for (int i = 5; i >= 0; i--) 
    begin
      @(posedge vif.sck);
      addr_val[i*4 +: 4] = vif.sio[3:0];
    end
    `uvm_info(get_type_name(), $sformatf("[QSPI_SLV] Sampled Flash Address: 0x%06h", addr_val), UVM_LOW)

    // Mode Phase
    mode_byte = 8'h00;
    for (int i = 1; i >= 0; i--)
    begin
      @(posedge vif.sck);
      mode_byte[i*4 +: 4] = vif.sio[3:0];
    end
    `uvm_info(get_type_name(), $sformatf("[QSPI_SLV] Sampled Mode Byte: 0x%02h", mode_byte), UVM_LOW)

    in_continuous_mode = (mode_byte == `QSPI_MODE_CONTINUOUS && cfg.continuous_mode_enabled);

    //  Dummy Phase
    repeat (cfg.dummy_cycles) 
	begin
      	@(posedge vif.sck);
    	end

    // Data Phase    
    `uvm_info(get_type_name(), $sformatf("[QSPI_SLV] Driving %0d bytes from memory starting at 0x%06h",cfg.line_size, addr_val), UVM_LOW)

    for (int b = 0; b < cfg.line_size; b++) 
    begin
      bit [7:0] data_byte;
      data_byte = cfg.mem.read_byte(addr_val + b);

      // Upper Nibble [7:4]
      @(negedge vif.sck);
      vif.drv_en   <= 1'b1;
      vif.drv_data <= data_byte[7:4];

      // Lower Nibble [3:0]
      @(negedge vif.sck);
      vif.drv_data <= data_byte[3:0];
    end

      @(posedge vif.ce_n);
    `uvm_info(get_type_name(), "[QSPI_SLV] QSPI line transfer completed, bus released", UVM_LOW)
  endtask 
endclass 
