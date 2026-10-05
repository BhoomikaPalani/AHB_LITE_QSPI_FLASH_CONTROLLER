`ifndef QSPI_SEQ_ITEM_SV
`define QSPI_SEQ_ITEM_SV

typedef enum bit [1:0] {
  QSPI_TRANS_RESET,
  QSPI_TRANS_READ_FIRST,
  QSPI_TRANS_READ_CONT
} qspi_trans_type_e;

class qspi_seq_item extends uvm_sequence_item;

  rand bit [7:0]             cmd;
  rand bit [23:0]            addr;
  rand bit [7:0]             mode;
  rand bit [7:0]             data[];
  rand qspi_trans_type_e     trans_type;
  rand int unsigned          line_size;

  `uvm_object_utils_begin(qspi_seq_item)
    `uvm_field_int(cmd,                       UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(addr,                      UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(mode,                      UVM_ALL_ON | UVM_HEX)
    `uvm_field_array_int(data,                UVM_ALL_ON | UVM_HEX)
    `uvm_field_enum(qspi_trans_type_e, trans_type, UVM_ALL_ON)
    `uvm_field_int(line_size,                 UVM_ALL_ON | UVM_DEC)
  `uvm_object_utils_end

  function new(string name = "qspi_seq_item");
    super.new(name);
    line_size = `QSPI_DEFAULT_LINE_SIZE;
  endfunction : new

  virtual function string convert2string();
    string s;
    s = $sformatf("Type=%s | CMD=0x%02h | ADDR=0x%06h | MODE=0x%02h | Bytes=%0d",
                  trans_type.name(), cmd, addr, mode, data.size());
    return s;
  endfunction : convert2string

endclass : qspi_seq_item

`endif 
