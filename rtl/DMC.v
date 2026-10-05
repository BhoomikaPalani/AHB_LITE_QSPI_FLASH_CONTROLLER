`timescale          1ns/1ps
`default_nettype    none

/*
    A parameterized Read-only Direct Mapped Cache
*/

/* NUM_LINES=16 ->cache contains 16 cache lines.
   LINE_SIZE=16 ->each cache line stores 16 bytes.
   total cache capacity is: 16lines x 16bytes = 256 bytes(default),byt from the top level design it can be overridden.
*/
module DMC  #(  parameter   NUM_LINES   = 16, 
                            LINE_SIZE   = 16 ) 
(
    input wire                      clk,
    input wire                      rst_n,
    // 
    input wire  [23:0]              A,
    output wire [31:0]              Do,
    output wire                     hit,
    //
    input wire [(LINE_SIZE*8)-1:0]  line,
    input wire                      wr
);

// A-> 24-bit address coming into the cache.{cache break this address into | TAG | INDEX | OFFSET | }
// Do-> 32-bit word, Data Output
// [(LINE_SIZE*8)-1:0]  line,-> entire cache line coming from the QSPI flash reader.i.e.LINE_SIZE*8 => 16*8 => 128 bits{16 bytes}.
// wr -> Write the newly fetched flash line into the cache.

    // Some local parameters for constants needed by the models
    localparam      LINE_WIDTH  = LINE_SIZE * 8;// 256 bits, no. of bits in one cache line
    localparam      LINE_WORDS  = LINE_SIZE / 4; // Each cache line can supply 8 AHB 32-bit words.{32byte/4byte= 8 words, one cache line will have 8 words ,each words are of 4 bytes}
    localparam      INDEX_WIDTH = $clog2(NUM_LINES); // how many address bits are required to select a cache line.log2(16)=4
    localparam      OFF_WIDTH   = $clog2(LINE_SIZE); // 5 address bits are required to identify one byte within a 32-byte cache line.
    localparam      TAG_WIDTH   = 24 - INDEX_WIDTH - OFF_WIDTH; // TAG=15(24-4-5=15)
    
    // The cache storage: Data, Tag, Valid
    reg [(LINE_WIDTH - 1): 0]   LINES   [(NUM_LINES-1):0];// [255:0]Lines[15:0]
    reg [(TAG_WIDTH - 1) : 0]   TAGS    [(NUM_LINES-1):0];// [14:0] Tags[15:0]
    reg                         VALID   [(NUM_LINES-1):0];// Valid[15:0]->one valid bit per cache line,1 ->this cache line contains valid data ,0 -> this cache line is empty/invalid

    // The Address Fields
    wire [(OFF_WIDTH - 1) : 0]  offset      =   A[(OFF_WIDTH - 1): 0]; // [4:0]offset= A[4:0]
    wire [(OFF_WIDTH - 3) : 0]  word_offset =   offset[(OFF_WIDTH - 1) : 2]; // [2:0]word_offset= offset[4:2]
    wire [(INDEX_WIDTH -1): 0]  index       =   A[(OFF_WIDTH+INDEX_WIDTH-1): (OFF_WIDTH)]; //[3:0]index= A[8:5]
    wire [(TAG_WIDTH-1)   : 0]  tag         =   A[23:(OFF_WIDTH+INDEX_WIDTH)];//[14:0]tag=A[23:9]

    // The hit signal has to do with the current 
    assign  hit =   VALID[index] & (TAGS[index] == tag);

    // output the word 
    assign Do = LINES[index][word_offset*32 +: 32];
    // Indexed Part-selection [base_expression +: width_constant]
    // clear the VALID flags
    integer i;
    always @ (posedge clk or negedge rst_n)
        if(rst_n == 1'b0) 
            for(i=0; i<NUM_LINES; i=i+1)
                VALID[i] <= 1'b0;//when reset=0, is applied the valid as become zero
        else  
            if(wr)
                VALID[index]    <= 1'b1;

    always @(posedge clk)
        if(wr) begin
            LINES[index]    <= line;//i.e.LINES[3] = that entire 32-byte line
            TAGS[index]     <= tag;
        end

endmodule

