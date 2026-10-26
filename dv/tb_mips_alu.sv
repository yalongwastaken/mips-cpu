// Checks every operand pair for every operation against SystemVerilog's own
// arithmetic, so a wrong result names the exact inputs.
module tb_mips_alu;
  import mips_pkg::*;

  alu_op_e alu_op_under_test;
  logic [7:0] operand_a, operand_b, alu_result;

  mips_alu dut (
    .op_i       (alu_op_under_test),
    .operand_a_i(operand_a),
    .operand_b_i(operand_b),
    .result_o   (alu_result)
  );

  // plain integer arithmetic, so the expected value shares nothing with the RTL's operators
  function automatic logic [7:0] expected_result(alu_op_e alu_op, int value_a, int value_b);
    int signed_a = (value_a >= 128) ? value_a - 256 : value_a;
    int signed_b = (value_b >= 128) ? value_b - 256 : value_b;
    unique case (alu_op)
      AluAdd:  return 8'((value_a + value_b) % 256);
      AluSub:  return 8'((value_a - value_b + 256) % 256);
      AluAnd:  return 8'(value_a & value_b);
      AluOr:   return 8'(value_a | value_b);
      AluSlt:  return (signed_a < signed_b) ? 8'd1 : 8'd0;
      default: return 'x;
    endcase
  endfunction

  initial begin
    alu_op_e alu_ops[5] = '{AluAdd, AluSub, AluAnd, AluOr, AluSlt};
    int unsigned mismatch_count = 0;

    foreach (alu_ops[op_index]) begin
      for (int value_a = 0; value_a < 256; value_a++) begin
        for (int value_b = 0; value_b < 256; value_b++) begin
          alu_op_under_test = alu_ops[op_index];
          operand_a         = 8'(value_a);
          operand_b         = 8'(value_b);
          #1;
          if (alu_result !== expected_result(alu_op_under_test, value_a, value_b)) begin
            mismatch_count++;
            $error("%s %0d, %0d: got %0d, expected %0d", alu_op_under_test.name(), value_a,
                   value_b, alu_result, expected_result(alu_op_under_test, value_a, value_b));
          end
        end
      end
    end

    if (mismatch_count != 0) begin
      $fatal(1, "FAIL tb_mips_alu: %0d mismatches", mismatch_count);
    end
    $display("PASS tb_mips_alu");
    $finish;
  end

endmodule
