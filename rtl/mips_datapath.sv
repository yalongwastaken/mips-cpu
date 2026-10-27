module mips_datapath (
  input  logic                                             clk_i,
  input  logic                                             rst_ni,
  input  mips_pkg::ctrl_t                                  ctrl_i,
  output logic            [                          31:0] instr_o,
  output logic                                             operands_equal_o,
  output logic                                             mem_req_o,
  output logic                                             mem_write_o,
  output logic            [mips_pkg::MemWordAddrWidth-1:0] mem_word_addr_o,
  output logic            [ mips_pkg::MemBytesPerWord-1:0] mem_byte_enable_o,
  output logic            [    mips_pkg::MemWordWidth-1:0] mem_write_data_o,
  input  logic            [    mips_pkg::MemWordWidth-1:0] mem_read_data_i,
  output logic            [       mips_pkg::DataWidth-1:0] io_o
);

  import mips_pkg::*;

  logic [PcWidth-1:0] pc_q, pc_d;
  logic [31:0] instr_q;
  logic [DataWidth-1:0] operand_a_q, operand_b_q;
  logic [DataWidth-1:0] alu_result_q, alu_result;
  logic [DataWidth-1:0] alu_operand_b;
  logic [DataWidth-1:0] io_q;

  logic [RegAddrWidth-1:0] rs, rt, rd;
  logic [DataWidth-1:0] immediate;
  logic [DataWidth-1:0] jump_target_word;
  logic [DataWidth-1:0] rf_read_data_a, rf_read_data_b;
  logic [      RegAddrWidth-1:0] rf_write_addr;
  logic [         DataWidth-1:0] rf_write_data;

  logic [         DataWidth-1:0] data_byte_addr;
  logic [  MemWordAddrWidth-1:0] data_word_addr;
  logic [  MemWordAddrWidth-1:0] pc_word_addr;
  logic [MemByteOffsetWidth-1:0] data_byte_offset;
  logic [MemByteOffsetWidth-1:0] data_byte_lane;
  logic [         DataWidth-1:0] loaded_byte;

  assign rs               = instr_q[25:21];
  assign rt               = instr_q[20:16];
  assign rd               = instr_q[15:11];
  assign immediate        = instr_q[DataWidth-1:0];
  assign jump_target_word = instr_q[DataWidth-1:0];

  // ---------------------------------------------------------------------------
  // Program counter: code spans the whole memory, so the PC is wider than the
  // data path and has its own adders. Branch offsets wrap at the PC's width.
  // ---------------------------------------------------------------------------
  always_comb begin
    unique case (ctrl_i.pc_sel)
      PcPlus4:        pc_d = pc_q + PcWidth'(MemBytesPerWord);
      PcBranchTarget: pc_d = pc_q + {immediate, MemByteOffsetWidth'(0)};
      PcJumpTarget:   pc_d = {jump_target_word, MemByteOffsetWidth'(0)};
      default:        pc_d = pc_q;
    endcase
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      pc_q <= '0;
    end else if (ctrl_i.pc_write) begin
      pc_q <= pc_d;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      instr_q <= '0;
    end else if (ctrl_i.instr_write) begin
      instr_q <= mem_read_data_i;
    end
  end

  assign rf_write_addr = (ctrl_i.rf_write_sel == RfWriteLoadByte) ? rt : rd;
  assign rf_write_data = (ctrl_i.rf_write_sel == RfWriteLoadByte) ? loaded_byte : alu_result_q;

  mips_register_file u_register_file (
    .clk_i,
    .rst_ni,
    .read_addr_a_i (rs),
    .read_addr_b_i (rt),
    .read_data_a_o (rf_read_data_a),
    .read_data_b_o (rf_read_data_b),
    .write_enable_i(ctrl_i.rf_write),
    .write_addr_i  (rf_write_addr),
    .write_data_i  (rf_write_data)
  );

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      operand_a_q <= '0;
      operand_b_q <= '0;
    end else if (ctrl_i.operands_write) begin
      operand_a_q <= rf_read_data_a;
      operand_b_q <= rf_read_data_b;
    end
  end

  assign alu_operand_b = (ctrl_i.alu_b_sel == AluBImmediate) ? immediate : operand_b_q;

  mips_alu u_alu (
    .op_i       (ctrl_i.alu_op),
    .operand_a_i(operand_a_q),
    .operand_b_i(alu_operand_b),
    .result_o   (alu_result)
  );

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      alu_result_q <= '0;
    end else if (ctrl_i.alu_result_write) begin
      alu_result_q <= alu_result;
    end
  end

  assign operands_equal_o = operand_a_q == operand_b_q;

  // ---------------------------------------------------------------------------
  // Memory: big-endian, so byte offset 0 is the word's most significant byte.
  // Data addresses come from the ALU, so they reach only the bottom of memory.
  // ---------------------------------------------------------------------------
  assign data_byte_addr = alu_result_q;
  assign data_byte_offset = data_byte_addr[MemByteOffsetWidth-1:0];
  assign data_byte_lane = MemByteOffsetWidth'(MemBytesPerWord - 1) - data_byte_offset;
  assign loaded_byte = mem_read_data_i[32'(data_byte_lane)*DataWidth+:DataWidth];

  assign mem_req_o = ctrl_i.mem_req;
  assign mem_write_o = ctrl_i.mem_write;
  assign data_word_addr = MemWordAddrWidth'(data_byte_addr[DataWidth-1:MemByteOffsetWidth]);
  assign pc_word_addr = pc_q[PcWidth-1:MemByteOffsetWidth];
  assign mem_word_addr_o = (ctrl_i.mem_addr_sel == MemAddrPc) ? pc_word_addr : data_word_addr;
  assign mem_byte_enable_o = ctrl_i.mem_write ? MemBytesPerWord'(1 << data_byte_lane) : '0;
  assign mem_write_data_o = {MemBytesPerWord{operand_b_q}};

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      io_q <= '0;
    end else if (ctrl_i.mem_write && data_byte_addr == IoPortAddr) begin
      io_q <= operand_b_q;
    end
  end

  assign instr_o = instr_q;
  assign io_o    = io_q;

endmodule
