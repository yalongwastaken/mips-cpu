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
  logic        [    MemWordWidth-1:0] unused_read_port_data;

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

  // port 1 is a second read-only port the multicycle core has no use for;
  // VERBOSE exists only in the simulation model, which otherwise prints every access
  sky130_sram_1kbyte_1rw1r_32x256_8 #(
`ifndef SYNTHESIS
    .VERBOSE(0)
`endif
  ) u_sram (
    .clk0  (clk_i),
    .csb0  (~mem_req),
    .web0  (~mem_write),
    .wmask0(mem_byte_enable),
    .addr0 (mem_word_addr),
    .din0  (mem_write_data),
    .dout0 (mem_read_data),
    .clk1  (clk_i),
    .csb1  (1'b1),
    .addr1 ('0),
    .dout1 (unused_read_port_data)
  );

endmodule
