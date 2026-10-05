class qspi_memory_model extends uvm_object;

  `uvm_object_utils(qspi_memory_model)

    bit [7:0] mem [bit [23:0]]; //max addressable capacity is 16MB

    bit is_initialized = 1'b0;

  function new(string name = "qspi_memory_model");
    super.new(name);
  endfunction 

   function void write_byte(bit [23:0] addr, bit [7:0] val);
    mem[addr] = val;
  endfunction : write_byte

    function bit [7:0] read_byte(bit [23:0] addr);
    if (mem.exists(addr))
    begin
      return mem[addr];
    end 
    else 
    begin
           return addr[7:0] ^ addr[15:8] ^ 8'h5A;
    end
  endfunction 

   function void write_word(bit [23:0] addr, bit [31:0] val);
    mem[addr + 0] = val[7:0];
    mem[addr + 1] = val[15:8];
    mem[addr + 2] = val[23:16];
    mem[addr + 3] = val[31:24];
  endfunction : write_word

  
  function bit [31:0] read_word(bit [23:0] addr);
    bit [31:0] val;
    val[7:0]   = read_byte(addr + 0);
    val[15:8]  = read_byte(addr + 1);
    val[23:16] = read_byte(addr + 2);
    val[31:24] = read_byte(addr + 3);
    return val;
  endfunction : read_word

    function void load_random(int unsigned num_bytes = 65536); //64KB
    for (int unsigned i = 0; i < num_bytes; i++) begin
      mem[i] = $urandom_range(0, 255);
    end
    is_initialized = 1'b1;
  endfunction : load_random

   function void load_pattern(bit [7:0] pattern, int unsigned num_bytes = 65536);
    for (int unsigned i = 0; i < num_bytes; i++) begin
      mem[i] = pattern;
    end
    is_initialized = 1'b1;
  endfunction 

  function void load_alternating(bit [7:0] p0 = 8'hAA, bit [7:0] p1 = 8'h55, int unsigned num_bytes = 65536);
    for (int unsigned i = 0; i < num_bytes; i++)
    begin
      mem[i] = (i % 2 == 0) ? p0 : p1;
    end
    is_initialized = 1'b1;
  endfunction 

  function void clear();
    mem.delete();
    is_initialized = 1'b0;
  endfunction 

endclass 
