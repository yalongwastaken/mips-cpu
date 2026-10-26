module mips_alu (
  input  mips_pkg::alu_op_e                           op_i,
  input  logic              [mips_pkg::DataWidth-1:0] operand_a_i,
  input  logic              [mips_pkg::DataWidth-1:0] operand_b_i,
  output logic              [mips_pkg::DataWidth-1:0] result_o
);

  import mips_pkg::*;

  always_comb begin
    unique case (op_i)
      AluAdd:  result_o = operand_a_i + operand_b_i;
      AluSub:  result_o = operand_a_i - operand_b_i;
      AluAnd:  result_o = operand_a_i & operand_b_i;
      AluOr:   result_o = operand_a_i | operand_b_i;
      AluSlt:  result_o = DataWidth'($signed(operand_a_i) < $signed(operand_b_i));
      default: result_o = '0;
    endcase
  end

endmodule
