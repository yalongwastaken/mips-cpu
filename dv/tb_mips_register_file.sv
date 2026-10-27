// Writes a distinct value to every register, then reads each back through both
// ports. $0 must still read zero after being written.
module tb_mips_register_file;
  import mips_pkg::*;

  localparam int unsigned LastRegIndex = RegCount - 1;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  logic [RegAddrWidth-1:0] read_addr_a, read_addr_b, write_addr;
  logic [DataWidth-1:0] read_data_a, read_data_b, write_data;
  logic write_enable;

  initial forever #5 clk = ~clk;

  mips_register_file dut (
    .clk_i         (clk),
    .rst_ni        (rst_n),
    .read_addr_a_i (read_addr_a),
    .read_addr_b_i (read_addr_b),
    .read_data_a_o (read_data_a),
    .read_data_b_o (read_data_b),
    .write_enable_i(write_enable),
    .write_addr_i  (write_addr),
    .write_data_i  (write_data)
  );

  function automatic logic [DataWidth-1:0] compute_written_value(int unsigned reg_index);
    return DataWidth'('hA5 ^ (reg_index * 7));
  endfunction

  function automatic logic [DataWidth-1:0] compute_expected_read_value(int unsigned reg_index);
    return (reg_index == 0) ? '0 : compute_written_value(reg_index);
  endfunction

  initial begin
    int unsigned mismatch_count = 0;

    write_enable = 1'b0;
    write_addr   = '0;
    write_data   = '0;
    read_addr_a  = '0;
    read_addr_b  = '0;
    repeat (2) @(posedge clk);
    rst_n = 1'b1;

    for (int unsigned reg_index = 0; reg_index < RegCount; reg_index++) begin
      @(negedge clk);
      write_enable = 1'b1;
      write_addr   = RegAddrWidth'(reg_index);
      write_data   = compute_written_value(reg_index);
    end
    @(negedge clk);
    write_enable = 1'b0;

    for (int unsigned reg_index = 0; reg_index < RegCount; reg_index++) begin
      int unsigned port_b_reg_index;
      logic [DataWidth-1:0] expected_read_data_a, expected_read_data_b;
      port_b_reg_index     = LastRegIndex - reg_index;
      expected_read_data_a = compute_expected_read_value(reg_index);
      expected_read_data_b = compute_expected_read_value(port_b_reg_index);
      read_addr_a          = RegAddrWidth'(reg_index);
      read_addr_b          = RegAddrWidth'(port_b_reg_index);
      #1;
      if (read_data_a !== expected_read_data_a) begin
        mismatch_count++;
        $error("port a, $%0d: got %h, expected %h", reg_index, read_data_a, expected_read_data_a);
      end
      if (read_data_b !== expected_read_data_b) begin
        mismatch_count++;
        $error("port b, $%0d: got %h, expected %h", port_b_reg_index, read_data_b,
               expected_read_data_b);
      end
    end

    if (mismatch_count != 0) begin
      $fatal(1, "FAIL tb_mips_register_file: %0d mismatches", mismatch_count);
    end
    $display("PASS tb_mips_register_file");
    $finish;
  end

endmodule
