`include "ahb_defines.svh"

package ahb_types_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  typedef enum logic [1:0] {
    HTRANS_IDLE   = 2'b00, 
    HTRANS_BUSY   = 2'b01, 
    HTRANS_NONSEQ = 2'b10, 
    HTRANS_SEQ    = 2'b11  
  } htrans_e;

  typedef enum logic [2:0] {
    HBURST_SINGLE = 3'b000, 
    HBURST_INCR   = 3'b001,
    HBURST_WRAP4  = 3'b010, 
    HBURST_INCR4  = 3'b011,
    HBURST_WRAP8  = 3'b100, 
    HBURST_INCR8  = 3'b101, 
    HBURST_WRAP16 = 3'b110,
    HBURST_INCR16 = 3'b111  
  } hburst_e;

  typedef enum logic [2:0] {
    HSIZE_8BIT    = 3'b000, // Byte
    HSIZE_16BIT   = 3'b001, // Halfword
    HSIZE_32BIT   = 3'b010, // Word 
    HSIZE_64BIT   = 3'b011, // Doubleword
    HSIZE_128BIT  = 3'b100, // 4-word line 
    HSIZE_256BIT  = 3'b101, // 8-word line
    HSIZE_512BIT  = 3'b110, 
    HSIZE_1024BIT = 3'b111   
  } hsize_e;

   typedef enum logic [0:0] {
    HRESP_OKAY  = 1'b0, 
    HRESP_ERROR = 1'b1  
  } hresp_e;

  typedef enum logic [0:0] {
    AHB_READ  = 1'b0,
    AHB_WRITE = 1'b1
  } hwrite_e;

  function automatic int get_size_in_bytes(hsize_e size);
    case (size)
      HSIZE_8BIT:    return 1;
      HSIZE_16BIT:   return 2;
      HSIZE_32BIT:   return 4;
      HSIZE_64BIT:   return 8;
      HSIZE_128BIT:  return 16;
      HSIZE_256BIT:  return 32;
      HSIZE_512BIT:  return 64;
      HSIZE_1024BIT: return 128;
      default:       return 4;
    endcase
  endfunction

   function automatic int get_burst_beats(hburst_e burst);
    case (burst)
      HBURST_SINGLE: return 1;
      HBURST_INCR:   return 1; // Default 
      HBURST_WRAP4:  return 4;
      HBURST_INCR4:  return 4;
      HBURST_WRAP8:  return 8;
      HBURST_INCR8:  return 8;
      HBURST_WRAP16: return 16;
      HBURST_INCR16: return 16;
      default:       return 1;
    endcase
  endfunction

   function automatic bit is_wrapping_burst(hburst_e burst);
    return (burst == HBURST_WRAP4 || burst == HBURST_WRAP8 || burst == HBURST_WRAP16);
  endfunction

  function automatic logic [`AHB_ADDR_WIDTH-1:0] calculate_next_addr(
    logic [`AHB_ADDR_WIDTH-1:0] current_addr,
    hburst_e burst,
    hsize_e size
  );
    int num_bytes;
    int num_beats;
    logic [`AHB_ADDR_WIDTH-1:0] wrap_boundary;
    logic [`AHB_ADDR_WIDTH-1:0] wrap_mask;
    logic [`AHB_ADDR_WIDTH-1:0] next_addr;

    num_bytes = get_size_in_bytes(size);
    num_beats = get_burst_beats(burst);

    if (is_wrapping_burst(burst)) begin
      int total_burst_bytes = num_bytes * num_beats;
      wrap_mask = total_burst_bytes - 1;
      wrap_boundary = current_addr & ~wrap_mask;
      next_addr = current_addr + num_bytes;
      if ((next_addr & ~wrap_mask) != wrap_boundary) begin
        next_addr = wrap_boundary + (next_addr & wrap_mask);
      end
    end else begin
      next_addr = current_addr + num_bytes;
    end

    return next_addr;
  endfunction

endpackage 
