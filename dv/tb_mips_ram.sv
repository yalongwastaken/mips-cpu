// Writes each word's own index into it and reads each back on the next edge, then
// checks that each byte enable writes only its own byte, and that neither a write
// nor a cycle without a request disturbs the read data or the memory.
module tb_mips_ram;
  import mips_pkg::*;

  logic                               clk = 1'b0;
  logic                               mem_req;
  logic                               mem_write;
  logic        [MemWordAddrWidth-1:0] mem_word_addr;
  logic        [ MemBytesPerWord-1:0] mem_byte_enable;
  logic        [    MemWordWidth-1:0] mem_write_data;
  logic        [    MemWordWidth-1:0] mem_read_data;
  int unsigned                        mismatch_count = 0;

  initial forever #5 clk = ~clk;

  mips_ram dut (
    .clk_i        (clk),
    .req_i        (mem_req),
    .write_i      (mem_write),
    .word_addr_i  (mem_word_addr),
    .byte_enable_i(mem_byte_enable),
    .write_data_i (mem_write_data),
    .read_data_o  (mem_read_data)
  );

  // inputs change between edges, so the next rising edge takes them cleanly
  task automatic drive_cycle(
      logic cycle_req, logic cycle_write, logic [MemWordAddrWidth-1:0] cycle_word_addr,
      logic [MemBytesPerWord-1:0] cycle_byte_enable, logic [MemWordWidth-1:0] cycle_write_data);
    @(negedge clk);
    mem_req         = cycle_req;
    mem_write       = cycle_write;
    mem_word_addr   = cycle_word_addr;
    mem_byte_enable = cycle_byte_enable;
    mem_write_data  = cycle_write_data;
    @(posedge clk);
    #1;
  endtask

  task automatic expect_read_data(logic [MemWordWidth-1:0] expected_read_data, string check_name);
    if (mem_read_data !== expected_read_data) begin
      mismatch_count++;
      $error("%s: read %h, expected %h", check_name, mem_read_data, expected_read_data);
    end
  endtask

  initial begin
    logic [MemWordWidth-1:0] lane_write_data;
    logic [MemWordWidth-1:0] expected_word_0 = '0;

    for (int unsigned word_index = 0; word_index < MemWordCount; word_index++) begin
      drive_cycle(1'b1, 1'b1, MemWordAddrWidth'(word_index), '1, MemWordWidth'(word_index));
    end
    for (int unsigned word_index = 0; word_index < MemWordCount; word_index++) begin
      drive_cycle(1'b1, 1'b0, MemWordAddrWidth'(word_index), '0, '0);
      expect_read_data(MemWordWidth'(word_index), $sformatf("word %0d", word_index));
    end

    // each round writes a byte unique to the round and the lane into every lane, so
    // a byte that lands in the wrong lane or in a lane not enabled shows up
    for (int unsigned enabled_lane = 0; enabled_lane < MemBytesPerWord; enabled_lane++) begin
      for (int unsigned filled_lane = 0; filled_lane < MemBytesPerWord; filled_lane++) begin
        lane_write_data[filled_lane*DataWidth+:DataWidth] =
            DataWidth'(enabled_lane * MemBytesPerWord + filled_lane + 1);
      end
      drive_cycle(1'b1, 1'b1, 0, MemBytesPerWord'(1 << enabled_lane), lane_write_data);
      expected_word_0[enabled_lane*DataWidth+:DataWidth] =
          lane_write_data[enabled_lane*DataWidth+:DataWidth];
      drive_cycle(1'b1, 1'b0, 0, '0, '0);
      expect_read_data(expected_word_0, $sformatf("word 0 after writing lane %0d", enabled_lane));
    end

    drive_cycle(1'b1, 1'b0, 1, '0, '0);
    drive_cycle(1'b1, 1'b1, 2, '1, '0);
    expect_read_data(MemWordWidth'(1), "read data after a write");
    drive_cycle(1'b0, 1'b1, 3, '1, '0);
    expect_read_data(MemWordWidth'(1), "read data after a cycle without a request");
    drive_cycle(1'b1, 1'b0, 3, '0, '0);
    expect_read_data(MemWordWidth'(3), "word 3 after a write without a request");
    drive_cycle(1'b1, 1'b0, 2, '0, '0);
    expect_read_data('0, "word 2 after its write");

    if (mismatch_count != 0) begin
      $fatal(1, "FAIL tb_mips_ram: %0d mismatches", mismatch_count);
    end
    $display("PASS tb_mips_ram");
    $finish;
  end

endmodule
