// Checks every operand pair for every operation against SystemVerilog's own
// arithmetic, so a wrong result names the exact inputs.
module tb_mips_alu;
  import mips_pkg::*;

  localparam int OperandValueCount  = 2 ** DataWidth;
  localparam int FirstNegativeValue = OperandValueCount / 2;

  alu_op_e alu_op_under_test;
  logic [DataWidth-1:0] operand_a, operand_b, alu_result;

  mips_alu dut (
    .op_i       (alu_op_under_test),
    .operand_a_i(operand_a),
    .operand_b_i(operand_b),
    .result_o   (alu_result)
  );

  // plain integer arithmetic, so the expected value shares nothing with the RTL's operators
  function automatic logic [DataWidth-1:0] compute_expected_alu_result(alu_op_e alu_op, int value_a,
                                                                       int value_b);
    int signed_a = (value_a >= FirstNegativeValue) ? value_a - OperandValueCount : value_a;
    int signed_b = (value_b >= FirstNegativeValue) ? value_b - OperandValueCount : value_b;
    unique case (alu_op)
      AluAdd:  return DataWidth'((value_a + value_b) % OperandValueCount);
      AluSub:  return DataWidth'((value_a - value_b + OperandValueCount) % OperandValueCount);
      AluAnd:  return DataWidth'(value_a & value_b);
      AluOr:   return DataWidth'(value_a | value_b);
      AluSlt:  return DataWidth'(signed_a < signed_b);
      default: return 'x;
    endcase
  endfunction

  initial begin
    alu_op_e alu_ops[5] = '{AluAdd, AluSub, AluAnd, AluOr, AluSlt};
    foreach (alu_ops[op_index]) begin
      for (int value_a = 0; value_a < OperandValueCount; value_a++) begin
        for (int value_b = 0; value_b < OperandValueCount; value_b++) begin
          alu_op_under_test = alu_ops[op_index];
          operand_a         = DataWidth'(value_a);
          operand_b         = DataWidth'(value_b);
          #1;
          if (alu_result !== compute_expected_alu_result(alu_op_under_test, value_a, value_b)) begin
            $fatal(1, "FAIL tb_mips_alu: %s %0d, %0d: got %0d, expected %0d",
                   alu_op_under_test.name(), value_a, value_b, alu_result,
                   compute_expected_alu_result(alu_op_under_test, value_a, value_b));
          end
        end
      end
    end

    $display("PASS tb_mips_alu");
    $finish;
  end

endmodule
