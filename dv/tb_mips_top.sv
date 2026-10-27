// Runs one program image on the whole chip, which reports its verdict on the I/O
// port as mips_test_pkg describes.
module tb_mips_top;

  // far longer than any test program runs, so reaching it means the program hung
  localparam int unsigned VerdictTimeoutCycles = 10000;

  logic                           clk = 1'b0;
  logic                           rst_n = 1'b0;
  logic [mips_pkg::DataWidth-1:0] io_port;

  initial forever #5 clk = ~clk;

  mips_top dut (
    .clk_i (clk),
    .rst_ni(rst_n),
    .io_o  (io_port)
  );

  string program_hex;

  // the core runs an undecodable instruction as a no-op, so a program that strays
  // into empty memory would keep running; in simulation that is a failure
  always @(posedge clk) begin
    if (dut.ctrl.operands_write && dut.instr_kind == mips_pkg::InstrInvalid) begin
      $fatal(1, "FAIL %s: invalid instruction %h", program_hex, dut.instr);
    end
  end

  initial begin
    if (!$value$plusargs("program=%s", program_hex)) begin
      $fatal(1, "missing +program=<image.hex>");
    end
    $readmemh(program_hex, dut.u_ram.memory_words);

    repeat (2) @(posedge clk);
    rst_n = 1'b1;

    for (
        int unsigned cycle_count = 0;
        cycle_count < VerdictTimeoutCycles && io_port == '0;
        cycle_count++
    ) begin
      @(posedge clk);
    end

    if (io_port == '0) begin
      $fatal(1, "FAIL %s: no verdict after %0d cycles", program_hex, VerdictTimeoutCycles);
    end else if (io_port != mips_test_pkg::PassCode) begin
      $fatal(1, "FAIL %s: check %0d failed", program_hex, io_port);
    end

    for (
        int unsigned cycle_count = 0;
        cycle_count < VerdictTimeoutCycles && io_port != '0;
        cycle_count++
    ) begin
      @(posedge clk);
    end

    if (io_port != '0) begin
      $fatal(1, "FAIL %s: pass code without its closing zero", program_hex);
    end
    $display("PASS %s", program_hex);
    $finish;
  end

endmodule
