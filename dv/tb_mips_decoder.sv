// Checks that each supported encoding decodes to its kind and ALU operation,
// and that every unsupported opcode or funct decodes as invalid.
module tb_mips_decoder;
  import mips_pkg::*;

  logic        [31:0] instr;
  instr_kind_e        decoded_kind;
  alu_op_e            decoded_alu_op;
  int unsigned        mismatch_count = 0;

  mips_decoder dut (
    .instr_i (instr),
    .kind_o  (decoded_kind),
    .alu_op_o(decoded_alu_op)
  );

  task automatic expect_decode(logic [5:0] opcode, logic [5:0] funct, instr_kind_e expected_kind,
                               alu_op_e expected_alu_op);
    instr = {opcode, 20'hABCDE, funct};
    #1;
    if (decoded_kind !== expected_kind) begin
      mismatch_count++;
      $error("opcode %b funct %b: kind %s, expected %s", opcode, funct, decoded_kind.name(),
             expected_kind.name());
    end
    if (expected_kind == InstrAlu && decoded_alu_op !== expected_alu_op) begin
      mismatch_count++;
      $error("funct %b: alu_op %s, expected %s", funct, decoded_alu_op.name(),
             expected_alu_op.name());
    end
  endtask

  initial begin
    expect_decode(OpLb, 6'h00, InstrLoadByte, AluAdd);
    expect_decode(OpSb, 6'h00, InstrStoreByte, AluAdd);
    expect_decode(OpBeq, 6'h00, InstrBranchEqual, AluAdd);
    expect_decode(OpJ, 6'h00, InstrJump, AluAdd);
    expect_decode(OpRType, FunctAdd, InstrAlu, AluAdd);
    expect_decode(OpRType, FunctSub, InstrAlu, AluSub);
    expect_decode(OpRType, FunctAnd, InstrAlu, AluAnd);
    expect_decode(OpRType, FunctOr, InstrAlu, AluOr);
    expect_decode(OpRType, FunctSlt, InstrAlu, AluSlt);

    for (int funct_value = 0; funct_value < 64; funct_value++) begin
      if (!(6'(funct_value) inside {FunctAdd, FunctSub, FunctAnd, FunctOr, FunctSlt})) begin
        expect_decode(OpRType, 6'(funct_value), InstrInvalid, AluAdd);
      end
    end
    for (int opcode_value = 0; opcode_value < 64; opcode_value++) begin
      if (!(6'(opcode_value) inside {OpRType, OpJ, OpBeq, OpLb, OpSb})) begin
        expect_decode(6'(opcode_value), 6'h00, InstrInvalid, AluAdd);
      end
    end

    if (mismatch_count != 0) begin
      $fatal(1, "FAIL tb_mips_decoder: %0d mismatches", mismatch_count);
    end
    $display("PASS tb_mips_decoder");
    $finish;
  end

endmodule
