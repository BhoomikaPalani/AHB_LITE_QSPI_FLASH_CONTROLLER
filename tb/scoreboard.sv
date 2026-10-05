`uvm_analysis_imp_decl(_ahb)
`uvm_analysis_imp_decl(_qspi)

class qspi_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(qspi_scoreboard)

   uvm_analysis_imp_ahb  #(ahb_master_seq_item, qspi_scoreboard) ahb_export;
  uvm_analysis_imp_qspi #(qspi_seq_item,qspi_scoreboard) qspi_export;

    qspi_memory_model ref_mem;

   int unsigned match_count        = 0;
  int unsigned mismatch_count     = 0;
  int unsigned ahb_trans_count    = 0;
  int unsigned qspi_trans_count   = 0;
  int unsigned cache_hit_count    = 0;
  int unsigned cache_miss_count   = 0;

   bit qspi_activity_seen = 1'b0;

  function new(string name = "qspi_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    ahb_export  = new("ahb_export", this);
    qspi_export = new("qspi_export", this);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction : build_phase

   virtual function void write_qspi(qspi_seq_item item);
    qspi_trans_count++;
    qspi_activity_seen = 1'b1;

    `uvm_info("SCB_QSPI", $sformatf("[SCB] Received QSPI Transfer: ADDR=0x%06h CMD=0x%02h TYPE=%s",
              item.addr, item.cmd, item.trans_type.name()), UVM_LOW)

    if (item.trans_type != QSPI_TRANS_RESET)
    begin
      // Verify line alignment of requested flash address (lower 5 bits must be 0 for 32-byte line)
      if (item.addr[4:0] !== 5'b00000) 
      begin
        `uvm_warning("QSPI_ALIGN", $sformatf("Flash read address 0x%06h is not 32-byte line-aligned!", item.addr))
      end
      else 
      begin
        `uvm_info("SCB_QSPI_LINE", $sformatf("[SCB] Observed QSPI Line Fetch at ADDR=0x%06h (%0d bytes)",
                  item.addr, item.data.size()), UVM_LOW)
      end
    end
  endfunction 
 
  virtual function void write_ahb(ahb_master_seq_item txn);
    int beats;
    ahb_trans_count++;

    `uvm_info("SCB_AHB", $sformatf("[SCB] Received AHB Transfer: ADDR=0x%08h HWRITE=%s BURST=%s",
              txn.haddr, txn.hwrite.name(), txn.hburst.name()), UVM_LOW)

    if (txn.hwrite == AHB_READ)
    begin
      beats = ahb_types_pkg::get_burst_beats(txn.hburst);

      for (int i = 0; i < beats; i++) 
      begin
        logic [31:0] beat_addr;
        logic [31:0] act_data;
        logic [31:0] exp_data;

        beat_addr = txn.get_beat_addr(i);
        act_data  = txn.hrdata[i];
        exp_data  = ref_mem.read_word(beat_addr[23:0]);

        if (act_data === exp_data) 
	begin
          match_count++;
          `uvm_info("SCB_MATCH", $sformatf("[PASS] ADDR=0x%08h | HRDATA=0x%08h | EXPECTED=0x%08h",
                    beat_addr, act_data, exp_data), UVM_LOW)
        end 
	else 
	begin
          mismatch_count++;
          `uvm_error("SCB_MISMATCH", $sformatf("[FAIL] ADDR=0x%08h | HRDATA=0x%08h | EXPECTED=0x%08h",
                     beat_addr, act_data, exp_data))
        end
      end

     
      if (qspi_activity_seen)
      begin
        cache_miss_count++;
        `uvm_info("SCB_MISS", $sformatf("[SCB] Transaction at ADDR=0x%08h verified as CACHE MISS (fetched via QSPI)", txn.haddr), UVM_LOW)
      end 
      else 
      begin
        cache_hit_count++;
        `uvm_info("SCB_HIT", $sformatf("[SCB] Transaction at ADDR=0x%08h verified as CACHE HIT (0 QSPI bus cycles)", txn.haddr), UVM_LOW)
      end

          qspi_activity_seen = 1'b0;
    end
  endfunction 
 
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("SCB_REPORT", "=======================================================", UVM_NONE)
    `uvm_info("SCB_REPORT", "             QSPI CONTROLLER SCOREBOARD REPORT         ", UVM_NONE)
    `uvm_info("SCB_REPORT", "=======================================================", UVM_NONE)
    `uvm_info("SCB_REPORT", $sformatf(" Total AHB Transfers Monitored : %0d", ahb_trans_count), UVM_NONE)
    `uvm_info("SCB_REPORT", $sformatf(" Total Word Matches (PASSED)    : %0d", match_count), UVM_NONE)
    `uvm_info("SCB_REPORT", $sformatf(" Total Word Mismatches (FAILED)  : %0d", mismatch_count), UVM_NONE)
    `uvm_info("SCB_REPORT", $sformatf(" Total Cache Hits Verified      : %0d", cache_hit_count), UVM_NONE)
    `uvm_info("SCB_REPORT", $sformatf(" Total Cache Misses Verified    : %0d", cache_miss_count), UVM_NONE)
    `uvm_info("SCB_REPORT", $sformatf(" Total QSPI Line Fetches        : %0d", qspi_trans_count), UVM_NONE)
    `uvm_info("SCB_REPORT", "=======================================================", UVM_NONE)

    if (mismatch_count == 0 && match_count > 0)
    begin
      `uvm_info("SCB_REPORT", "  >>> TEST STATUS: ALL CHECKS PASSED PERFECTLY! <<<    ", UVM_NONE)
    end 
    else if (mismatch_count > 0) 
    begin
      `uvm_error("SCB_REPORT", " >>> TEST STATUS: FAILURES DETECTED! <<<             ")
    end
    `uvm_info("SCB_REPORT", "=======================================================", UVM_NONE)
  endfunction

endclass 
