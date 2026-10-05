// 1. power_on_rst_test: Verify reset functionality

class power_on_rst_test extends base_test;
  `uvm_component_utils(power_on_rst_test)

  function new(string name = "power_on_rst_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction 

  virtual task run_phase(uvm_phase phase);
    seq_power_on_rst seq;
    phase.raise_objection(this);
 
    `uvm_info(get_type_name(), ">>> Running Test 1: power_on_rst_test <<<", UVM_LOW)
    seq = seq_power_on_rst::type_id::create("seq");
    seq.start(env.ahb_m_agent.sequencer);

    #500ns;
    phase.drop_objection(this);
  endtask 
endclass


// 2. base_single_read_test: Verify basic cache-miss (cold) read
// ------------------------------------------------------------------
class base_single_read_test extends base_test;
  `uvm_component_utils(base_single_read_test)

  function new(string name = "base_single_read_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction 

  virtual task run_phase(uvm_phase phase);
    seq_base_single_read seq;
    phase.raise_objection(this);
   
    `uvm_info(get_type_name(), ">>> Running Test 2: base_single_read_test <<<", UVM_LOW)
    seq = seq_base_single_read::type_id::create("seq");
    seq.start(env.ahb_m_agent.sequencer);

    #5000ns;
    phase.drop_objection(this);
  endtask 
endclass


// 3. cache_hit_repeat_read_test: Verify cache-hit read after prior miss
//-------------------------------------------------------------------
class cache_hit_repeat_read_test extends base_test;
  `uvm_component_utils(cache_hit_repeat_read_test)

  function new(string name = "cache_hit_repeat_read_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction 

  virtual task run_phase(uvm_phase phase);
    seq_cache_hit_repeat seq;
    phase.raise_objection(this);
   
    `uvm_info(get_type_name(), ">>> Running Test 3: cache_hit_repeat_read_test <<<", UVM_LOW)
    seq = seq_cache_hit_repeat::type_id::create("seq");
    seq.start(env.ahb_m_agent.sequencer);

    #500ns;
    phase.drop_objection(this);
  endtask 
endclass 


// 4. line_boundary_first_word_test: Verify access to first word of line
// ----------------------------------------------------------------
class line_boundary_first_word_test extends base_test;
  `uvm_component_utils(line_boundary_first_word_test)

  function new(string name = "line_boundary_first_word_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction 

  virtual task run_phase(uvm_phase phase);
    seq_line_boundary_first_word seq;
    phase.raise_objection(this);
  
    `uvm_info(get_type_name(), ">>> Running Test 4: line_boundary_first_word_test <<<", UVM_LOW)
    seq = seq_line_boundary_first_word::type_id::create("seq");
    seq.start(env.ahb_m_agent.sequencer);

    #500ns;
    phase.drop_objection(this);
  endtask
endclass


// 5. line_boundary_last_word_test: Verify access to last word of line
//-------------------------------------------------------
class line_boundary_last_word_test extends base_test;
  `uvm_component_utils(line_boundary_last_word_test)

  function new(string name = "line_boundary_last_word_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    seq_line_boundary_last_word seq;
    phase.raise_objection(this);
  
    `uvm_info(get_type_name(), ">>> Running Test 5: line_boundary_last_word_test <<<", UVM_LOW)
    seq = seq_line_boundary_last_word::type_id::create("seq");
    seq.start(env.ahb_m_agent.sequencer);

    #500ns;
    phase.drop_objection(this);
  endtask
endclass 


// 6. addr_min_boundary_test: Verify operation at lowest address (0x000000)
//------------------------------------------------------
class addr_min_boundary_test extends base_test;
  `uvm_component_utils(addr_min_boundary_test)

  function new(string name = "addr_min_boundary_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction 

  virtual task run_phase(uvm_phase phase);
    seq_addr_min_boundary seq;
    phase.raise_objection(this);
 
    `uvm_info(get_type_name(), ">>> Running Test 6: addr_min_boundary_test <<<", UVM_LOW)
    seq = seq_addr_min_boundary::type_id::create("seq");
    seq.start(env.ahb_m_agent.sequencer);

    #500ns;
    phase.drop_objection(this);
  endtask 
endclass 


// 7. addr_max_boundary_test: Verify operation at highest address (0x00FF_FFFC)
//-------------------------------------------------------
class addr_max_boundary_test extends base_test;
  `uvm_component_utils(addr_max_boundary_test)

  function new(string name = "addr_max_boundary_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction 

  virtual function void configure_memory();
    // Ensure memory covers the top of the 16MB space
    `uvm_info(get_type_name(), "Pre-loading flash memory at high boundary range", UVM_LOW)
    for (int unsigned a = 32'h00FF_FF00; a <= 32'h00FF_FFFF; a++) begin
      cfg.ref_mem.write_byte(a[23:0], $urandom_range(0, 255));
    end
  endfunction : configure_memory

  virtual task run_phase(uvm_phase phase);
    seq_addr_max_boundary seq;
    phase.raise_objection(this);

    `uvm_info(get_type_name(), ">>> Running Test 7: addr_max_boundary_test <<<", UVM_LOW)
    seq = seq_addr_max_boundary::type_id::create("seq");
    seq.start(env.ahb_m_agent.sequencer);

    #500ns;
    phase.drop_objection(this);
  endtask 
endclass 

// 8. all_lines_walk_test: Verify access to all 16 cache lines
//----------------------------------------------------
class all_lines_walk_test extends base_test;
  `uvm_component_utils(all_lines_walk_test)

  function new(string name = "all_lines_walk_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction 

  virtual task run_phase(uvm_phase phase);
    seq_all_lines_walk seq;
    phase.raise_objection(this);
  
    `uvm_info(get_type_name(), ">>> Running Test 8: all_lines_walk_test <<<", UVM_LOW)
    seq = seq_all_lines_walk::type_id::create("seq");
    seq.start(env.ahb_m_agent.sequencer);

    #500ns;
    phase.drop_objection(this);
  endtask 
endclass 


// 9. all_zeroes_data_test: Verify all-zero flash content
//------------------------------------------------------------
class all_zeroes_data_test extends base_test;
  `uvm_component_utils(all_zeroes_data_test)

  function new(string name = "all_zeroes_data_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction 

  virtual function void configure_memory();
    `uvm_info(get_type_name(), "Pre-loading memory with all zeroes (8'h00)", UVM_LOW)
    cfg.ref_mem.load_pattern(8'h00, 65536);
  endfunction : configure_memory

  virtual task run_phase(uvm_phase phase);
    seq_all_zeroes seq;
    phase.raise_objection(this);

    `uvm_info(get_type_name(), ">>> Running Test 9: all_zeroes_data_test <<<", UVM_LOW)
    seq = seq_all_zeroes::type_id::create("seq");
    seq.start(env.ahb_m_agent.sequencer);

    #500ns;
    phase.drop_objection(this);
  endtask 
endclass


// 10. all_ones_data_test: Verify all-one flash content
//--------------------------------------------
class all_ones_data_test extends base_test;
  `uvm_component_utils(all_ones_data_test)

  function new(string name = "all_ones_data_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction 

  virtual function void configure_memory();
    `uvm_info(get_type_name(), "Pre-loading memory with all ones (8'hFF)", UVM_LOW)
    cfg.ref_mem.load_pattern(8'hFF, 65536);
  endfunction 

  virtual task run_phase(uvm_phase phase);
    seq_all_ones seq;
    phase.raise_objection(this);
  
    `uvm_info(get_type_name(), ">>> Running Test 10: all_ones_data_test <<<", UVM_LOW)
    seq = seq_all_ones::type_id::create("seq");
    seq.start(env.ahb_m_agent.sequencer);

    #500ns;
    phase.drop_objection(this);
  endtask 
endclass 

// 11. alternating_bits_pattern_test: Verify alternating bit patterns
//-----------------------------------------------------------
class alternating_bits_pattern_test extends base_test;
  `uvm_component_utils(alternating_bits_pattern_test)

  function new(string name = "alternating_bits_pattern_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction 

  virtual function void configure_memory();
    `uvm_info(get_type_name(), "Pre-loading memory with alternating pattern (0xAA / 0x55)", UVM_LOW)
    cfg.ref_mem.load_alternating(8'hAA, 8'h55, 65536);
  endfunction 

  virtual task run_phase(uvm_phase phase);
    seq_alternating_bits seq;
    phase.raise_objection(this);
  
    `uvm_info(get_type_name(), ">>> Running Test 11: alternating_bits_pattern_test <<<", UVM_LOW)
    seq = seq_alternating_bits::type_id::create("seq");
    seq.start(env.ahb_m_agent.sequencer);

    #500ns;
    phase.drop_objection(this);
  endtask 
endclass 


// 12. back_to_back_miss_requests_test: Verify consecutive misses
//--------------------------------------------------
class back_to_back_miss_requests_test extends base_test;
  `uvm_component_utils(back_to_back_miss_requests_test)

  function new(string name = "back_to_back_miss_requests_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction 

  virtual task run_phase(uvm_phase phase);
    seq_back_to_back_miss seq;
    phase.raise_objection(this);
  
    `uvm_info(get_type_name(), ">>> Running Test 12: back_to_back_miss_requests_test <<<", UVM_LOW)
    seq = seq_back_to_back_miss::type_id::create("seq");
    seq.start(env.ahb_m_agent.sequencer);

    #500ns;
    phase.drop_objection(this);
  endtask 
endclass



// 13. pipelined_cache_hits_test: Verify 1-transfer/cycle throughput
//-----------------------------------------------------------
class pipelined_cache_hits_test extends base_test;
  `uvm_component_utils(pipelined_cache_hits_test)

  function new(string name = "pipelined_cache_hits_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction 

  virtual task run_phase(uvm_phase phase);
    seq_pipelined_cache_hits seq;
    phase.raise_objection(this);
    phase.phase_done.set_drain_time(this, 200ns);

    `uvm_info(get_type_name(), ">>> Running Test 13: pipelined_cache_hits_test <<<", UVM_LOW)
    seq = seq_pipelined_cache_hits::type_id::create("seq");
    seq.start(env.ahb_m_agent.sequencer);

    #500ns;
    phase.drop_objection(this);
  endtask 
endclass 

// 14. pipelined_miss_then_hit_test: Verify address hold during HREADY=0
//--------------------------------------------------------------------------
class pipelined_miss_then_hit_test extends base_test;
  `uvm_component_utils(pipelined_miss_then_hit_test)

  function new(string name = "pipelined_miss_then_hit_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction 

  virtual task run_phase(uvm_phase phase);
    seq_pipelined_miss_then_hit seq;
    phase.raise_objection(this);
    phase.phase_done.set_drain_time(this, 200ns);

    `uvm_info(get_type_name(), ">>> Running Test 14: pipelined_miss_then_hit_test <<<", UVM_LOW)
    seq = seq_pipelined_miss_then_hit::type_id::create("seq");
    seq.start(env.ahb_m_agent.sequencer);

    #500ns;
    phase.drop_objection(this);
  endtask
endclass 

//----------------------------------------
class ahb_burst_test extends base_test;
  `uvm_component_utils(ahb_burst_test)

  function new(string name = "ahb_burst_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    seq_burst_read seq;
    phase.raise_objection(this);
    phase.phase_done.set_drain_time(this, 500ns);

    `uvm_info(get_type_name(), ">>> Running Test 13: ahb_burst_test <<<", UVM_LOW)
    seq = seq_burst_read::type_id::create("seq");
    seq.start(env.ahb_m_agent.sequencer);

    #1000ns;
    phase.drop_objection(this);
  endtask : run_phase
endclass : ahb_burst_test
