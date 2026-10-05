`timescale          1ns/1ps
`default_nettype    none


/* NUM_LINES=16 -> The cache has 16 lines.
   LINES_SIZE=32 -> Each cache line contains 32 bytes.
   so, total cache storage is: 16 lines x 32 bytes = 512 bytes.
  
   RESET_CYCLES = 999 -> This controls the software-reset timing of the flash controller. */

module EF_QSPI_XIP_CTRL_AHBL #(parameter    NUM_LINES   = 16, 
                                            LINE_SIZE   = 32, 
                                            RESET_CYCLES= 999 )
(
    // AHB-Lite Slave Interface
    input   wire                HCLK,
    input   wire                HRESETn,
    input   wire                HSEL,
    input   wire [31:0]         HADDR,
    input   wire [1:0]          HTRANS,
    input   wire                HWRITE,
    input   wire                HREADY, //bus ready input from previous master
    output  reg                 HREADYOUT, //wait-state generator(0=stall CPU,1=READY)
    output  wire [31:0]         HRDATA,

    // External Interface to Quad I/O
    output  wire                sck,
    output  wire                ce_n,//active low chip enable
    input   wire [3:0]          din, // 4-bit data input from flash
    output  wire [3:0]          dout, //4-bit data output to flash
    output  wire [3:0]          douten  //output enable(1=drive dout, 0=tri-state)   
);

    localparam [1:0]    IDLE    =   2'b00;
    localparam [1:0]    WAIT    =   2'b01; // Cache miss state, waiting for QSPI fetch
    localparam [1:0]    RW      =   2'b10; // Cache updated, asserting HREADYOUT=1
    localparam      OFF_WIDTH   = $clog2(LINE_SIZE); //calculates the number of address bits needed to represent the byte offset inside one cache line.log2(32)=5 ->A 32 byte line has offsets 0 to 31 which require 5bits.]

    // Cache wires/buses
    wire [31:0]                 c_datao; //data coming out of the cache
    wire [(LINE_SIZE*8)-1:0]    c_line; // 32*8=256 bits 
    wire                        c_hit; // 1-> cache hit, 0 -> cache miss
    reg [2:0]                   c_wr; //It is a timing/control signal that tells the wrapper and DMC when the flash-fetched cache line should be written/used.
    wire [23:0]                 c_A; // 24 bit flash address

    // Flash Reader wires
    wire                        fr_rd; //start a flash read
    wire                        fr_done; //flash reader done -> QSPI flash reader has finished fetching the cache line.

    wire                        doe; // Data Output Enable
    
    reg [1:0]   state, nstate;

    //AHB-Lite Address Phase Regs
    reg             last_HSEL;
    reg [31:0]      last_HADDR;
    reg             last_HWRITE;
    reg [1:0]       last_HTRANS;
    reg             last_valid;

    wire            valid = HSEL & HTRANS[1] & HREADY;

    always@ (posedge HCLK or negedge HRESETn) 
    begin
        if(~HRESETn) begin
            last_HSEL   <= 'b0;
            last_HADDR  <= 'b0;
            last_HWRITE <= 'b0;
            last_HTRANS <= 'b0;
            last_valid  <= 'b0;
        end
        else if(HREADY) begin
            last_HSEL   <= HSEL;
            last_HADDR  <= HADDR;
            last_HWRITE <= HWRITE;
            last_HTRANS <= HTRANS;
            last_valid  <= valid;
        end
    end

    always @ (posedge HCLK or negedge HRESETn)
        if(HRESETn == 0) 
            state <= IDLE;
        else 
            state <= nstate;

    always @* begin
        nstate = IDLE;
        case(state)
            IDLE :  if(valid & c_hit) 
                            nstate = IDLE;
                        else if(valid & ~c_hit) 
                            nstate = WAIT;

            WAIT :  if(c_wr[2]) 
                            nstate = RW; 
                        else  
                            nstate = WAIT;

            RW   :   nstate = IDLE;
        endcase
    end

    always @(posedge HCLK or negedge HRESETn)
        if(!HRESETn) 
            HREADYOUT <= 1'b1;
        else
            case (state)
                IDLE :  if(valid & c_hit) 
                            HREADYOUT <= 1'b1;
                        else if(valid & ~c_hit) 
                            HREADYOUT <= 1'b0;
                        else 
                            HREADYOUT <= 1'b1;

                WAIT :  HREADYOUT <= 1'b0;

                RW   :  HREADYOUT <= 1'b1;
            endcase
        
    assign fr_rd        =   ( HTRANS[1] & HSEL & HREADY & ~c_hit & (state==IDLE) ) |
            ( HTRANS[1] & HSEL & HREADY & ~c_hit & (state==RW) ); //flash read request

    assign c_A          =   (state != IDLE) ? last_HADDR[23:0] : HADDR; //Flash address selection
    

    DMC #(  .NUM_LINES(NUM_LINES), 
            .LINE_SIZE(LINE_SIZE) ) 
    CACHE ( 
            .clk(HCLK), 
            .rst_n(HRESETn), 
            .A(c_A),
            .Do(c_datao), 
            .hit(c_hit), 
            .line(c_line), 
            .wr(c_wr[1]) 
        );

    EF_QSPI_XIP_CTRL #(     .NUM_LINES(NUM_LINES), 
                            .LINE_SIZE(LINE_SIZE), 
                            .RESET_CYCLES(RESET_CYCLES) )   
    FC (   
            .clk(HCLK), 
            .rst_n(HRESETn), 
            .addr({c_A[23:OFF_WIDTH], {OFF_WIDTH{1'b0}}}), 
            .rd(fr_rd), 
            .done(fr_done), 
            .line(c_line),
            .sck(sck), 
            .ce_n(ce_n), 
            .din(din), 
            .dout(dout), 
            .douten(doe) 
        );

    reg [31:0] cdata; // this register holding the final data returned to AHB.
    assign HRDATA   = cdata;
    
    always @(posedge HCLK)
        case (state)
            IDLE: if(valid & c_hit) cdata <= c_datao;
            WAIT: if(c_wr[1]) cdata <= c_datao; // cache write, when cache miss: flash->c_line -> DMC Cache -> c_datao -> cdata -> HRDATA
        endcase

    always @ (posedge HCLK or negedge HRESETn) 
        if(~HRESETn)
            c_wr <= 'b0;
        else begin
            c_wr[0] <= fr_done;
            c_wr[1] <= c_wr[0];
            c_wr[2] <= c_wr[1];
        end
  
    assign douten = {4{doe}};
    
endmodule

