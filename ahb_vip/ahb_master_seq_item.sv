class ahb_master_seq_item extends uvm_sequence_item;

  rand logic [`AHB_ADDR_WIDTH-1:0] haddr;
  rand htrans_e                    htrans;
  rand hwrite_e                    hwrite;
  rand hsize_e                     hsize;
  rand hburst_e                    hburst;
  rand logic [`AHB_PROT_WIDTH-1:0] hprot;
  rand logic                       hmastlock;

   rand logic [`AHB_DATA_WIDTH-1:0] hwdata[];
       logic [`AHB_DATA_WIDTH-1:0] hrdata[];
       hresp_e                     hresp[];

  rand int  busy_cycles[];  
  rand int post_idle_cycles;

 
  `uvm_object_utils_begin(ahb_master_seq_item)
    `uvm_field_int(haddr,                UVM_ALL_ON | UVM_HEX)
    `uvm_field_enum(htrans_e, htrans,    UVM_ALL_ON)
    `uvm_field_enum(hwrite_e, hwrite,    UVM_ALL_ON)
    `uvm_field_enum(hsize_e, hsize,      UVM_ALL_ON)
    `uvm_field_enum(hburst_e, hburst,    UVM_ALL_ON)
    `uvm_field_int(hprot,                UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(hmastlock,            UVM_ALL_ON | UVM_BIN)
    `uvm_field_array_int(hwdata,         UVM_ALL_ON | UVM_HEX)
    `uvm_field_array_int(hrdata,         UVM_ALL_ON | UVM_HEX)
    `uvm_field_array_enum(hresp_e, hresp,UVM_ALL_ON)
    `uvm_field_array_int(busy_cycles,    UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(post_idle_cycles,     UVM_ALL_ON | UVM_DEC)
  `uvm_object_utils_end

   constraint c_hsize_limit {
    hsize <= HSIZE_32BIT;
  }

  constraint c_addr_alignment {
    if (hsize == HSIZE_16BIT) {
      haddr[0] == 1'b0;
    } else if (hsize == HSIZE_32BIT) {
      haddr[1:0] == 2'b00;
    }
  }

   constraint c_array_sizes {
    hwdata.size() == ahb_types_pkg::get_burst_beats(hburst);
    busy_cycles.size() == ahb_types_pkg::get_burst_beats(hburst);
  }

   constraint c_1kb_boundary {
    if (!ahb_types_pkg::is_wrapping_burst(hburst) && hburst != HBURST_SINGLE) {
      (haddr % 1024) + (ahb_types_pkg::get_burst_beats(hburst) * ahb_types_pkg::get_size_in_bytes(hsize)) <= 1024;
    }
  }

  constraint c_busy_cycles {
    foreach (busy_cycles[i]) {
      busy_cycles[i] inside {[0:2]};
    }
    post_idle_cycles inside {[0:2]};
  }

  constraint c_default_prot {
    soft htrans == HTRANS_NONSEQ;
    soft hprot == 4'b0011;
    soft hmastlock == 1'b0;
  }

   function new(string name = "ahb_master_seq_item");
    super.new(name);
  endfunction 

  function void post_randomize();
    int beats = ahb_types_pkg::get_burst_beats(hburst);
    hrdata = new[beats];
    hresp  = new[beats];
    foreach (hresp[i]) 
    begin
      hresp[i] = HRESP_OKAY;
    end
  endfunction 

   function logic [`AHB_ADDR_WIDTH-1:0] get_beat_addr(int beat_idx);
    logic [`AHB_ADDR_WIDTH-1:0] cur_addr = haddr;
    for (int i = 0; i < beat_idx; i++) begin
      cur_addr = ahb_types_pkg::calculate_next_addr(cur_addr, hburst, hsize);
    end
    return cur_addr;
  endfunction 

  virtual function string convert2string();
    string s;
    s = $sformatf("HADDR=0x%08h | %s | %s | %s | Beats=%0d",
                  haddr, hwrite.name(), hsize.name(), hburst.name(),
                  ahb_types_pkg::get_burst_beats(hburst));
    return s;
  endfunction 

endclass 

