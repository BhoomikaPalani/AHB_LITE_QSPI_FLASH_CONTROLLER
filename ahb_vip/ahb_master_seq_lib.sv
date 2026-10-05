//------------------ Base Master Sequence-------------------------

class ahb_master_base_seq extends uvm_sequence #(ahb_master_seq_item);

  `uvm_object_utils(ahb_master_base_seq)

  function new(string name = "ahb_master_base_seq");
    super.new(name);
  endfunction 

  virtual task write_word(
    input  logic [`AHB_ADDR_WIDTH-1:0] addr,
    input  logic [`AHB_DATA_WIDTH-1:0] data,
    output hresp_e                     resp
  );
    ahb_master_seq_item item;
    item = ahb_master_seq_item::type_id::create("item");
    start_item(item);
    if (!item.randomize() with {
      haddr            == addr;
      hwrite           == AHB_WRITE;
      hsize            == HSIZE_32BIT;
      hburst           == HBURST_SINGLE;
      hwdata.size()    == 1;
      hwdata[0]        == data;
      busy_cycles.size() == 1;
      busy_cycles[0]   == 0;
      post_idle_cycles == 0;
    }) begin
      `uvm_fatal("RNDFAIL", "Randomization failed in write_word")
    end
    finish_item(item);
    resp = item.hresp[0];
  endtask 

  virtual task read_word(
    input  logic [`AHB_ADDR_WIDTH-1:0] addr,
    output logic [`AHB_DATA_WIDTH-1:0] data,
    output hresp_e                     resp
  );
    ahb_master_seq_item item;
    item = ahb_master_seq_item::type_id::create("item");
    start_item(item);
    if (!item.randomize() with {
      haddr            == addr;
      hwrite           == AHB_READ;
      hsize            == HSIZE_32BIT;
      hburst           == HBURST_SINGLE;
      hwdata.size()    == 1;
      busy_cycles.size() == 1;
      busy_cycles[0]   == 0;
      post_idle_cycles == 0;
    }) begin
      `uvm_fatal("RNDFAIL", "Randomization failed in read_word")
    end
    finish_item(item);
    data = item.hrdata[0];
    resp = item.hresp[0];
  endtask 

endclass 

//------------ Single Read/Write Sanity Sequence-------------

class ahb_master_single_rw_seq extends ahb_master_base_seq;

  `uvm_object_utils(ahb_master_single_rw_seq)

  rand logic [`AHB_ADDR_WIDTH-1:0] start_addr;
  rand logic [`AHB_DATA_WIDTH-1:0] test_data;

  constraint c_addr {
    start_addr[1:0] == 2'b00;
    start_addr < 32'h0000_1000;
  }

  function new(string name = "ahb_master_single_rw_seq");
    super.new(name);
  endfunction

  virtual task body();
    logic [`AHB_DATA_WIDTH-1:0] rdata;
    hresp_e resp;

    `uvm_info(get_type_name(), $sformatf("Executing Single Write to 0x%08h with data 0x%08h",
              start_addr, test_data), UVM_MEDIUM)
    write_word(start_addr, test_data, resp);

    `uvm_info(get_type_name(), $sformatf("Executing Single Read from 0x%08h", start_addr), UVM_MEDIUM)
    read_word(start_addr, rdata, resp);

    `uvm_info(get_type_name(), $sformatf("Readback result: 0x%08h (Expected: 0x%08h) Status: %s",
              rdata, test_data, resp.name()), UVM_LOW)
  endtask

endclass 

// Burst Transfer Sequence (INCR4, INCR8, INCR16, WRAP4, etc.)
//----------------------------------------------------------------------
class ahb_master_burst_seq extends ahb_master_base_seq;

  `uvm_object_utils(ahb_master_burst_seq)

  rand int num_transactions;

  constraint c_num_trans {
    num_transactions inside {[5:15]};
  }

  function new(string name = "ahb_master_burst_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    ahb_master_seq_item item;

    for (int i = 0; i < num_transactions; i++) begin
      item = ahb_master_seq_item::type_id::create($sformatf("burst_item_%0d", i));
      start_item(item);
      if (!item.randomize() with {
        hburst inside {HBURST_INCR4, HBURST_WRAP4, HBURST_INCR8, HBURST_WRAP8, HBURST_INCR16, HBURST_WRAP16};
        hsize  inside {HSIZE_8BIT, HSIZE_16BIT, HSIZE_32BIT};
        haddr  inside {[32'h0000_0000 : 32'h0000_1F00]};
      }) begin
        `uvm_fatal("RNDFAIL", "Burst randomization failed")
      end
      finish_item(item);
    end
  endtask : body

endclass : ahb_master_burst_seq


//----------------------------------------------------------------------
// Wrapping Burst Specific Sequence
//----------------------------------------------------------------------
class ahb_master_wrap_seq extends ahb_master_base_seq;

  `uvm_object_utils(ahb_master_wrap_seq)

  function new(string name = "ahb_master_wrap_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    ahb_master_seq_item item;
    hburst_e wrap_types[3] = '{HBURST_WRAP4, HBURST_WRAP8, HBURST_WRAP16};

    foreach (wrap_types[k]) begin
      // Test unaligned starting addresses to force multiple wraps
      item = ahb_master_seq_item::type_id::create("wrap_item");
      start_item(item);
      if (!item.randomize() with {
        hburst == wrap_types[k];
        hsize  == HSIZE_32BIT;
        hwrite == AHB_WRITE;
        // Start near boundary to exercise wrap condition
        haddr[3:0] == 4'hC;
      }) begin
        `uvm_fatal("RNDFAIL", "Wrap sequence randomization failed")
      end
      finish_item(item);
    end
  endtask : body

endclass : ahb_master_wrap_seq


//----------------------------------------------------------------------
// Busy Transfer Insertion Sequence
//----------------------------------------------------------------------
class ahb_master_busy_seq extends ahb_master_base_seq;

  `uvm_object_utils(ahb_master_busy_seq)

  function new(string name = "ahb_master_busy_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    ahb_master_seq_item item;
    item = ahb_master_seq_item::type_id::create("busy_item");
    start_item(item);
    if (!item.randomize() with {
      hburst == HBURST_INCR8;
      hsize  == HSIZE_32BIT;
      hwrite == AHB_WRITE;
      foreach (busy_cycles[i]) {
        if (i > 0) busy_cycles[i] == 2;
        else busy_cycles[i] == 0;
      }
    }) begin
      `uvm_fatal("RNDFAIL", "Busy sequence randomization failed")
    end
    finish_item(item);
  endtask : body

endclass : ahb_master_busy_seq


//----------------------------------------------------------------------
// Error Response Test Sequence
//----------------------------------------------------------------------
class ahb_master_error_seq extends ahb_master_base_seq;

  `uvm_object_utils(ahb_master_error_seq)

  function new(string name = "ahb_master_error_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    logic [`AHB_DATA_WIDTH-1:0] rdata;
    hresp_e resp;

    `uvm_info(get_type_name(), "Attempting access to reserved/error address 0xFFFF_0000", UVM_LOW)
    // Access high reserved memory location configured to trigger slave error
    read_word(32'hFFFF_0000, rdata, resp);
    `uvm_info(get_type_name(), $sformatf("Observed response: %s", resp.name()), UVM_LOW)
  endtask : body

endclass : ahb_master_error_seq

