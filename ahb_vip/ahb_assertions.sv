//----------------------------------------------------------------------
// Project      : ARM AHB-Lite UVM Verification IP (VIP)
// Standard     : ARM IHI 0033A (AMBA 3 AHB-Lite Protocol v1.0)
// File Name    : ahb_assertions.sv
// Description  : Formal SystemVerilog Assertions (SVA) for AHB-Lite Protocol
//                NOTE: This is a plain SV module bound inside ahb_lite_if.
//                      Uses $error() - UVM macros are NOT available here.
//----------------------------------------------------------------------

`ifndef AHB_ASSERTIONS_SV
`define AHB_ASSERTIONS_SV

`include "ahb_defines.svh"

module ahb_assertions (
  input logic                        HCLK,
  input logic                        HRESETn,
  input logic                        HSEL,
  input logic [`AHB_ADDR_WIDTH-1:0]  HADDR,
  input logic [`AHB_BURST_WIDTH-1:0] HBURST,
  input logic                        HMASTLOCK,
  input logic [`AHB_PROT_WIDTH-1:0]  HPROT,
  input logic [`AHB_SIZE_WIDTH-1:0]  HSIZE,
  input logic [`AHB_TRANS_WIDTH-1:0] HTRANS,
  input logic [`AHB_DATA_WIDTH-1:0]  HWDATA,
  input logic                        HWRITE,
  input logic [`AHB_DATA_WIDTH-1:0]  HRDATA,
  input logic                        HREADY,
  input logic                        HREADYOUT,
  input logic [`AHB_RESP_WIDTH-1:0]  HRESP
);

  import ahb_types_pkg::*;

  // Default clocking for all concurrent assertions
  default clocking ahb_cb @(posedge HCLK);
  endclocking

  default disable iff (!HRESETn);

  //--------------------------------------------------------------------
  // Rule 1: Address and Control stability during Wait States
  // Section 3.1: When HREADY is LOW, HADDR, HWRITE, HSIZE, HBURST,
  // HPROT and HTRANS must remain unchanged.
  //--------------------------------------------------------------------
  property p_addr_ctrl_stable_on_wait;
    (!HREADY && HTRANS != HTRANS_IDLE) |=>
      ($stable(HADDR) && $stable(HWRITE) && $stable(HSIZE) &&
       $stable(HBURST) && $stable(HPROT) && $stable(HTRANS));
  endproperty
  assert_addr_ctrl_stable_on_wait: assert property (p_addr_ctrl_stable_on_wait)
    else $error("[AHB_SVA] HADDR or control signals changed while HREADY was LOW! (Spec: Section 3.1)");

  //--------------------------------------------------------------------
  // Rule 2: Write Data stability during Wait States
  // Section 3.1: HWDATA must remain stable when HREADY is LOW during
  //              a write data phase.
  //--------------------------------------------------------------------
  logic write_data_phase;
  always_ff @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn)
      write_data_phase <= 1'b0;
    else if (HREADY)
      write_data_phase <= (HTRANS == HTRANS_NONSEQ || HTRANS == HTRANS_SEQ) && (HWRITE == AHB_WRITE);
  end

  property p_wdata_stable_on_wait;
    (write_data_phase && !HREADY) |=> $stable(HWDATA);
  endproperty
  assert_wdata_stable_on_wait: assert property (p_wdata_stable_on_wait)
    else $error("[AHB_SVA] HWDATA changed while HREADY was LOW during write data phase! (Spec: Section 3.1)");

  //--------------------------------------------------------------------
  // Rule 3: Two-Cycle ERROR Response
  // Section 3.5.2: ERROR response must span two cycles:
  //   Cycle 1: HRESP=ERROR, HREADYOUT=0
  //   Cycle 2: HRESP=ERROR, HREADYOUT=1
  //--------------------------------------------------------------------
  property p_two_cycle_error;
    (HSEL && HRESP == HRESP_ERROR && !HREADYOUT) |=>
      (HRESP == HRESP_ERROR && HREADYOUT);
  endproperty
  assert_two_cycle_error: assert property (p_two_cycle_error)
    else $error("[AHB_SVA] ERROR response violated the two-cycle protocol requirement! (Spec: Section 3.5.2)");

  //--------------------------------------------------------------------
  // Rule 4: Transfer Size vs Bus Width
  // Section 3.4: HSIZE cannot exceed 32-bit for a 32-bit data bus
  //--------------------------------------------------------------------
  property p_valid_hsize;
    HSIZE <= HSIZE_32BIT;
  endproperty
  assert_valid_hsize: assert property (p_valid_hsize)
    else $error("[AHB_SVA] HSIZE exceeds the 32-bit data bus width! (Spec: Section 3.4)");

  //--------------------------------------------------------------------
  // Rule 5: Address Natural Alignment
  // Section 3.4: HADDR must be naturally aligned to HSIZE
  //--------------------------------------------------------------------
  property p_addr_aligned;
    (HTRANS != HTRANS_IDLE) |->
      ((HSIZE == HSIZE_16BIT) -> (HADDR[0] == 1'b0)) and
      ((HSIZE == HSIZE_32BIT) -> (HADDR[1:0] == 2'b00));
  endproperty
  assert_addr_aligned: assert property (p_addr_aligned)
    else $error("[AHB_SVA] HADDR is not naturally aligned to HSIZE! (Spec: Section 3.4)");

  //--------------------------------------------------------------------
  // Rule 6: No 1KB Boundary Crossing in a Burst
  // Section 3.3.1: Burst transfers must not cross a 1KB boundary
  //--------------------------------------------------------------------
  property p_burst_1kb_boundary;
    (HREADY && (HTRANS == HTRANS_SEQ)) |->
      ((HADDR & ~`AHB_1KB_BOUNDARY_MASK) == ($past(HADDR) & ~`AHB_1KB_BOUNDARY_MASK));
  endproperty
  assert_burst_1kb_boundary: assert property (p_burst_1kb_boundary)
    else $error("[AHB_SVA] AHB Burst crossed a 1KB address boundary! (Spec: Section 3.3.1)");

  //--------------------------------------------------------------------
  // Rule 7: First Active Transfer After IDLE must be NONSEQ
  // Section 3.2: Following an IDLE cycle, a new burst must start NONSEQ
  //--------------------------------------------------------------------
  property p_idle_to_active;
    ($past(HTRANS) == HTRANS_IDLE && HTRANS != HTRANS_IDLE && $past(HRESETn)) |->
      (HTRANS == HTRANS_NONSEQ);
  endproperty
  assert_idle_to_active: assert property (p_idle_to_active)
    else $error("[AHB_SVA] Active transfer following IDLE must be NONSEQ! (Spec: Section 3.2)");

endmodule : ahb_assertions

`endif // AHB_ASSERTIONS_SV
