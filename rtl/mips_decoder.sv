module mips_decoder (
  input  logic                  [31:0] instr_i,
  output mips_pkg::instr_kind_e        kind_o,
  output mips_pkg::alu_op_e            alu_op_o
);

  import mips_pkg::*;

  logic [5:0] opcode;
  logic [5:0] funct;
  logic       funct_valid;

  assign opcode = instr_i[31:26];
  assign funct  = instr_i[5:0];

  always_comb begin
    funct_valid = 1'b1;
    unique case (funct)
      FunctAdd: alu_op_o = AluAdd;
      FunctSub: alu_op_o = AluSub;
      FunctAnd: alu_op_o = AluAnd;
      FunctOr:  alu_op_o = AluOr;
      FunctSlt: alu_op_o = AluSlt;
      default: begin
        alu_op_o    = AluAdd;
        funct_valid = 1'b0;
      end
    endcase
  end

  always_comb begin
    unique case (opcode)
      OpLb:    kind_o = InstrLoadByte;
      OpSb:    kind_o = InstrStoreByte;
      OpRType: kind_o = funct_valid ? InstrAlu : InstrInvalid;
      OpBeq:   kind_o = InstrBranchEqual;
      OpJ:     kind_o = InstrJump;
      default: kind_o = InstrInvalid;
    endcase
  end

  // only the opcode and funct fields decide what an instruction is
  logic unused_instr_fields;
  assign unused_instr_fields = ^instr_i[25:6];

endmodule
