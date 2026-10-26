module mips_top (
  input  logic                           clk_i,
  input  logic                           rst_ni,
  output logic [mips_pkg::DataWidth-1:0] io_o
);

  import mips_pkg::*;

  ctrl_t                              ctrl;
  logic        [                31:0] instr;
  instr_kind_e                        instr_kind;
  alu_op_e                            instr_alu_op;
  logic                               operands_equal;

  logic                               mem_req;
  logic                               mem_write;
  logic        [MemWordAddrWidth-1:0] mem_word_addr;
  logic        [ MemBytesPerWord-1:0] mem_byte_enable;
  logic        [    MemWordWidth-1:0] mem_write_data;
  logic        [    MemWordWidth-1:0] mem_read_data;

  mips_decoder u_decoder (
    .instr_i (instr),
    .kind_o  (instr_kind),
    .alu_op_o(instr_alu_op)
  );

  mips_controller u_controller (
    .clk_i,
    .rst_ni,
    .instr_kind_i    (instr_kind),
    .instr_alu_op_i  (instr_alu_op),
    .operands_equal_i(operands_equal),
    .ctrl_o          (ctrl)
  );

  mips_datapath u_datapath (
    .clk_i,
    .rst_ni,
    .ctrl_i           (ctrl),
    .instr_o          (instr),
    .operands_equal_o (operands_equal),
    .mem_req_o        (mem_req),
    .mem_write_o      (mem_write),
    .mem_word_addr_o  (mem_word_addr),
    .mem_byte_enable_o(mem_byte_enable),
    .mem_write_data_o (mem_write_data),
    .mem_read_data_i  (mem_read_data),
    .io_o
  );

  mips_ram u_ram (
    .clk_i,
    .req_i        (mem_req),
    .write_i      (mem_write),
    .word_addr_i  (mem_word_addr),
    .byte_enable_i(mem_byte_enable),
    .write_data_i (mem_write_data),
    .read_data_o  (mem_read_data)
  );

endmodule
