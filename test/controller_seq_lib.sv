class qspi_controller_base_seq extends ahb_master_base_seq;

  `uvm_object_utils(qspi_controller_base_seq)

  function new(string name = "qspi_controller_base_seq");
    super.new(name);
  endfunction : new

  virtual task read_ahb(
    input  logic [31:0] addr,
    output logic [31:0] rdata,
    input  int          post_idle = 0
  );
    ahb_master_seq_item item;
    item = ahb_master_seq_item::type_id::create("item");
    start_item(item);
    if (!item.randomize() with {
      haddr              == addr;
      hwrite             == AHB_READ;
      hsize              == HSIZE_32BIT;
      hburst             == HBURST_SINGLE;
      hwdata.size()      == 1;
      busy_cycles.size() == 1;
      busy_cycles[0]     == 0;
      post_idle_cycles   == post_idle;
    }) begin
      `uvm_fatal("RNDFAIL", "Randomization failed in read_ahb")
    end
    finish_item(item);     
   // @(item.data_done);     // Wait for the event until Data Phase completes and HRDATA is sampled
    rdata = item.hrdata[0];
  endtask : read_ahb
endclass 

//----------------------------------------------------------------------
// 1. Power-On Reset Sequence

class seq_power_on_rst extends qspi_controller_base_seq;
  `uvm_object_utils(seq_power_on_rst)

  function new(string name = "seq_power_on_rst");
    super.new(name);
  endfunction : new

  virtual task body();
    logic [31:0] rdata;
    `uvm_info(get_type_name(), "Executing post-reset verification read", UVM_LOW)
    read_ahb(32'h0000_0000, rdata, 2);
  endtask 
endclass 

// 2. Base Single Read (Miss) Sequence
//----------------------------------------------------------------------
class seq_base_single_read extends qspi_controller_base_seq;
  `uvm_object_utils(seq_base_single_read)

  function new(string name = "seq_base_single_read");
    super.new(name);
  endfunction : new

  virtual task body();
    logic [31:0] rdata;
    `uvm_info(get_type_name(), "Executing Single Cold-Miss Read to 0x0000_00A0", UVM_LOW)
    read_ahb(32'h0000_00A0, rdata, 2);
  endtask 
endclass 

//----------------------------------------------------------------------
// 3. Cache-Hit Repeat Read Sequence

class seq_cache_hit_repeat extends qspi_controller_base_seq;
  `uvm_object_utils(seq_cache_hit_repeat)

  function new(string name = "seq_cache_hit_repeat");
    super.new(name);
  endfunction : new

  virtual task body();
    logic [31:0] rdata;

    `uvm_info(get_type_name(), "Step 1: Cold miss read to 0x0000_00A0 ", UVM_LOW)
    read_ahb(32'h0000_00A0, rdata, 1);

    `uvm_info(get_type_name(), "Step 2: Repeat read to exact same address 0x0000_00A0 (Cache Hit expected)", UVM_LOW)
    read_ahb(32'h0000_00A0, rdata, 1);

    `uvm_info(get_type_name(), "Step 3: Read different word within same line 0x0000_00A4 (Cache Hit expected)", UVM_LOW)
    read_ahb(32'h0000_00A4, rdata, 2);
  endtask 
endclass 

// 4. Line Boundary First Word Sequence (Offset 0)
//----------------------------------------------------------------------
class seq_line_boundary_first_word extends qspi_controller_base_seq;
  `uvm_object_utils(seq_line_boundary_first_word)

  function new(string name = "seq_line_boundary_first_word");
    super.new(name);
  endfunction : new

  virtual task body();
    logic [31:0] rdata;
    // 32'h0000_0200 has byte offset 0 (0x200 % 32 == 0)
    `uvm_info(get_type_name(), "Executing read to first word of line (offset 0): 0x0000_0200", UVM_LOW)
    read_ahb(32'h0000_0200, rdata, 2);
  endtask 
endclass 

// 5. Line Boundary Last Word Sequence (Offset 28 for LINE_SIZE=32)
//----------------------------------------------------------------------
class seq_line_boundary_last_word extends qspi_controller_base_seq;
  `uvm_object_utils(seq_line_boundary_last_word)

  function new(string name = "seq_line_boundary_last_word");
    super.new(name);
  endfunction : new

  virtual task body();
    logic [31:0] rdata;
    // 32'h0000_021C has byte offset 28 (0x21C % 32 == 28)
    `uvm_info(get_type_name(), "Executing read to last word of line (offset 28): 0x0000_021C", UVM_LOW)
    read_ahb(32'h0000_021C, rdata, 2);
  endtask : body
endclass : seq_line_boundary_last_word


// 6. Minimum Boundary Address Sequence (0x0000_0000)
//----------------------------------------------------------------------
class seq_addr_min_boundary extends qspi_controller_base_seq;
  `uvm_object_utils(seq_addr_min_boundary)

  function new(string name = "seq_addr_min_boundary");
    super.new(name);
  endfunction : new

  virtual task body();
    logic [31:0] rdata;
    `uvm_info(get_type_name(), "Executing read to minimum boundary address: 0x0000_0000", UVM_LOW)
    read_ahb(32'h0000_0000, rdata, 2);
  endtask : body
endclass : seq_addr_min_boundary


// 7. Maximum Boundary Address Sequence (0x00FF_FFFC)
//----------------------------------------------------------------------
class seq_addr_max_boundary extends qspi_controller_base_seq;
  `uvm_object_utils(seq_addr_max_boundary)

  function new(string name = "seq_addr_max_boundary");
    super.new(name);
  endfunction : new

  virtual task body();
    logic [31:0] rdata;
    // Maximum 24-bit aligned word address
    `uvm_info(get_type_name(), "Executing read to maximum boundary address: 0x00FF_FFFC", UVM_LOW)
    read_ahb(32'h00FF_FFFC, rdata, 2);
  endtask : body
endclass : seq_addr_max_boundary


// 8. All Lines Walk Sequence (16 distinct lines + all words in line)
//----------------------------------------------------------------------
class seq_all_lines_walk extends qspi_controller_base_seq;
  `uvm_object_utils(seq_all_lines_walk)

  function new(string name = "seq_all_lines_walk");
    super.new(name);
  endfunction : new

  virtual task body();
    logic [31:0] rdata;

    `uvm_info(get_type_name(), "Phase 1: Filling all 16 cache lines across distinct indices", UVM_LOW)
    for (int line = 0; line < 16; line++)
    begin
      logic [31:0] target_addr;
      target_addr = (line * 32); // Line-aligned address targeting line index 'line'
      `uvm_info(get_type_name(), $sformatf("Reading Line Index %0d at ADDR=0x%08h", line, target_addr), UVM_MEDIUM)
      read_ahb(target_addr, rdata, 1);
    end

    `uvm_info(get_type_name(), "Phase 2: Reading every word offset (words 0 to 7) within Line 0 (Cache Hits)", UVM_LOW)
    for (int word = 0; word < 8; word++) begin
      logic [31:0] target_addr;
      target_addr = (word * 4);
      `uvm_info(get_type_name(), $sformatf("Reading Word %0d of Line 0 at ADDR=0x%08h", word, target_addr), UVM_MEDIUM)
      read_ahb(target_addr, rdata, 1);
    end
  endtask : body
endclass : seq_all_lines_walk


// 9. All Zeroes Data Sequence
//----------------------------------------------------------------------
class seq_all_zeroes extends qspi_controller_base_seq;
  `uvm_object_utils(seq_all_zeroes)

  function new(string name = "seq_all_zeroes");
    super.new(name);
  endfunction : new

  virtual task body();
    logic [31:0] rdata;
    `uvm_info(get_type_name(), "Reading lines pre-loaded with all zeroes", UVM_LOW)
    read_ahb(32'h0000_0100, rdata, 1); // Cold miss
    read_ahb(32'h0000_0104, rdata, 1); // Hit
    read_ahb(32'h0000_0140, rdata, 2); // Different line miss
  endtask : body
endclass : seq_all_zeroes


// 10. All Ones Data Sequence
//----------------------------------------------------------------------
class seq_all_ones extends qspi_controller_base_seq;
  `uvm_object_utils(seq_all_ones)

  function new(string name = "seq_all_ones");
    super.new(name);
  endfunction : new

  virtual task body();
    logic [31:0] rdata;
    `uvm_info(get_type_name(), "Reading lines pre-loaded with all ones", UVM_LOW)
    read_ahb(32'h0000_0200, rdata, 1); // Cold miss
    read_ahb(32'h0000_0204, rdata, 1); // Hit
    read_ahb(32'h0000_0240, rdata, 2); // Different line miss
  endtask : body
endclass : seq_all_ones


// 11. Alternating Bits Pattern Sequence
//----------------------------------------------------------------------
class seq_alternating_bits extends qspi_controller_base_seq;
  `uvm_object_utils(seq_alternating_bits)

  function new(string name = "seq_alternating_bits");
    super.new(name);
  endfunction : new

  virtual task body();
    logic [31:0] rdata;
    `uvm_info(get_type_name(), "Reading lines pre-loaded with alternating 0xAA/0x55 pattern", UVM_LOW)
    read_ahb(32'h0000_0300, rdata, 1); // Cold miss
    read_ahb(32'h0000_0304, rdata, 1); // Hit
    read_ahb(32'h0000_0308, rdata, 2); // Hit
  endtask : body
endclass : seq_alternating_bits


// 12. Back-to-Back Miss Requests Sequence (Zero Idle cycles)
//----------------------------------------------------------------------
class seq_back_to_back_miss extends qspi_controller_base_seq;
  `uvm_object_utils(seq_back_to_back_miss)

  function new(string name = "seq_back_to_back_miss");
    super.new(name);
  endfunction : new

  virtual task body();
    logic [31:0] rdata;
    `uvm_info(get_type_name(), "Issuing consecutive cache misses with 0 idle cycles gap", UVM_LOW)
    read_ahb(32'h0000_0400, rdata, 0); // Miss Line A
    read_ahb(32'h0000_0500, rdata, 0); // Miss Line B
    read_ahb(32'h0000_0600, rdata, 0); // Miss Line C
    read_ahb(32'h0000_0700, rdata, 2); // Miss Line D
  endtask : body
endclass : seq_back_to_back_miss




// 13. Pipelined Back-to-Back Cache Hits Sequence (0-Wait States)
// Verifies 1-transfer-per-clock-cycle throughput on cache hits
//----------------------------------------------------------------------
class seq_pipelined_cache_hits extends qspi_controller_base_seq;
  `uvm_object_utils(seq_pipelined_cache_hits)

  function new(string name = "seq_pipelined_cache_hits");
    super.new(name);
  endfunction : new

  virtual task body();
    logic [31:0] rdata0, rdata1, rdata2, rdata3;

    `uvm_info(get_type_name(), "Phase 1: Pre-filling cache line at 0x0000_00A0 via cold miss", UVM_LOW)
    read_ahb(32'h0000_00A0, rdata0, 2);

    `uvm_info(get_type_name(), "Phase 2: Launching 3 pipelined back-to-back reads on consecutive cycles", UVM_LOW)
    fork
      read_ahb(32'h0000_00A0, rdata1, 0); // Cycle T
      read_ahb(32'h0000_00A4, rdata2, 0); // Cycle T+1 (Pipelined!)
      read_ahb(32'h0000_00A8, rdata3, 0); // Cycle T+2 (Pipelined!)
    join

    `uvm_info(get_type_name(), $sformatf("Pipelined Results: Word0=0x%08h, Word1=0x%08h, Word2=0x%08h",
              rdata1, rdata2, rdata3), UVM_LOW)
  endtask : body
endclass : seq_pipelined_cache_hits

// 14. Pipelined Miss with Address Stalled on Wait State Sequence
// Verifies address hold rule (Section 3.1) during HREADY=0 wait states
//----------------------------------------------------------------------
class seq_pipelined_miss_then_hit extends qspi_controller_base_seq;
  `uvm_object_utils(seq_pipelined_miss_then_hit)

  function new(string name = "seq_pipelined_miss_then_hit");
    super.new(name);
  endfunction : new

  virtual task body();
    logic [31:0] rdata1, rdata2;

    `uvm_info(get_type_name(), "Pipelining Miss (0x0000_0100) and Next Read (0x0000_0104)", UVM_LOW)
    fork
      read_ahb(32'h0000_0100, rdata1, 0); // Triggers cold miss (HREADY goes 0)
      read_ahb(32'h0000_0104, rdata2, 0); // Queued immediately; address held during miss
    join

    `uvm_info(get_type_name(), $sformatf("Results: Miss Data=0x%08h, Pipelined Hit Data=0x%08h",
              rdata1, rdata2), UVM_LOW)
  endtask : body
endclass : seq_pipelined_miss_then_hit

//--------------------------

class seq_burst_read extends qspi_controller_base_seq;
  `uvm_object_utils(seq_burst_read)

  function new(string name = "seq_burst_read");
    super.new(name);
  endfunction : new

  virtual task body();
    ahb_master_seq_item item;

    // 1. 4-Beat Incrementing Burst Read (INCR4)
    `uvm_info(get_type_name(), "Executing 4-Beat Incrementing Burst (INCR4) to 0x0000_0100", UVM_LOW)
    item = ahb_master_seq_item::type_id::create("item_incr4");
    start_item(item);
    if (!item.randomize() with {
      haddr  == 32'h0000_0100;
      hwrite == AHB_READ;
      hsize  == HSIZE_32BIT;
      hburst == HBURST_INCR4;
    }) `uvm_fatal("RNDFAIL", "Burst INCR4 randomization failed")
    finish_item(item);

    // 2. 8-Beat Incrementing Burst Read (INCR8)
    `uvm_info(get_type_name(), "Executing 8-Beat Incrementing Burst (INCR8) to 0x0000_0200", UVM_LOW)
    item = ahb_master_seq_item::type_id::create("item_incr8");
    start_item(item);
    if (!item.randomize() with {
      haddr  == 32'h0000_0200;
      hwrite == AHB_READ;
      hsize  == HSIZE_32BIT;
      hburst == HBURST_INCR8;
    }) `uvm_fatal("RNDFAIL", "Burst INCR8 randomization failed")
    finish_item(item);

    // 3. 4-Beat Wrapping Burst Read (WRAP4)
    `uvm_info(get_type_name(), "Executing 4-Beat Wrapping Burst (WRAP4) to 0x0000_030C", UVM_LOW)
    item = ahb_master_seq_item::type_id::create("item_wrap4");
    start_item(item);
    if (!item.randomize() with {
      haddr  == 32'h0000_030C;
      hwrite == AHB_READ;
      hsize  == HSIZE_32BIT;
      hburst == HBURST_WRAP4;
    }) `uvm_fatal("RNDFAIL", "Burst WRAP4 randomization failed")
    finish_item(item);
  endtask : body
endclass : seq_burst_read
