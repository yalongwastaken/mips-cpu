// Writes a distinct value to every register, then reads each back through both
// ports. $0 must still read zero after being written.
module tb_mips_register_file;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  logic [4:0] read_addr_a, read_addr_b, write_addr;
  logic [7:0] read_data_a, read_data_b, write_data;
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

  function automatic logic [7:0] value_for(int unsigned reg_index);
    return 8'(8'hA5 ^ (reg_index * 7));
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

    for (int unsigned reg_index = 0; reg_index < 32; reg_index++) begin
      @(negedge clk);
      write_enable = 1'b1;
      write_addr   = 5'(reg_index);
      write_data   = value_for(reg_index);
    end
    @(negedge clk);
    write_enable = 1'b0;

    for (int unsigned reg_index = 0; reg_index < 32; reg_index++) begin
      logic [7:0] expected_value;
      expected_value    = (reg_index == 0) ? 8'h00 : value_for(reg_index);
      read_addr_a = 5'(reg_index);
      read_addr_b = 5'(31 - reg_index);
      #1;
      if (read_data_a !== expected_value) begin
        mismatch_count++;
        $error("port a, $%0d: got %h, expected %h", reg_index, read_data_a, expected_value);
      end
      if (read_data_b !== ((reg_index == 31) ? 8'h00 : value_for(31 - reg_index))) begin
        mismatch_count++;
        $error("port b, $%0d: got %h", 31 - reg_index, read_data_b);
      end
    end

    if (mismatch_count != 0) begin
      $fatal(1, "FAIL tb_mips_register_file: %0d mismatches", mismatch_count);
    end
    $display("PASS tb_mips_register_file");
    $finish;
  end

endmodule
