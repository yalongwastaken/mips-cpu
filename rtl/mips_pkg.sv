package mips_pkg;

  parameter int unsigned DataWidth = 8;
  parameter int unsigned PcWidth = 10;
  parameter int unsigned RegAddrWidth = 5;
  parameter int unsigned MemWordAddrWidth = 8;
  parameter int unsigned MemWordWidth = 32;
  parameter int unsigned MemBytesPerWord = MemWordWidth / DataWidth;

  // a store to this byte address also drives the chip's output port
  parameter logic [DataWidth-1:0] IoPortAddr = 8'hFF;

  typedef enum logic [5:0] {
    OpRType = 6'b000000,
    OpJ     = 6'b000010,
    OpBeq   = 6'b000100,
    OpLb    = 6'b100000,
    OpSb    = 6'b101000
  } opcode_e;

  typedef enum logic [5:0] {
    FunctAdd = 6'b100000,
    FunctSub = 6'b100010,
    FunctAnd = 6'b100100,
    FunctOr  = 6'b100101,
    FunctSlt = 6'b101010
  } funct_e;

  typedef enum logic [2:0] {
    InstrLoadByte,
    InstrStoreByte,
    InstrAlu,
    InstrBranchEqual,
    InstrJump,
    InstrInvalid
  } instr_kind_e;

  typedef enum logic [2:0] {
    AluAdd,
    AluSub,
    AluAnd,
    AluOr,
    AluSlt
  } alu_op_e;

  typedef enum logic {
    MemAddrPc,
    MemAddrData
  } mem_addr_sel_e;

  typedef enum logic [1:0] {
    PcPlus4,
    PcBranchTarget,
    PcJumpTarget
  } pc_sel_e;

  typedef enum logic {
    AluBRegister,
    AluBImmediate
  } alu_b_sel_e;

  typedef enum logic {
    RfWriteLoadByte,
    RfWriteAluResult
  } rf_write_sel_e;

  typedef struct packed {
    logic          mem_req;
    logic          mem_write;
    mem_addr_sel_e mem_addr_sel;
    logic          instr_write;
    logic          pc_write;
    pc_sel_e       pc_sel;
    logic          operands_write;
    alu_op_e       alu_op;
    alu_b_sel_e    alu_b_sel;
    logic          alu_result_write;
    logic          rf_write;
    rf_write_sel_e rf_write_sel;
  } ctrl_t;

endpackage
