// Runs one program image on the whole chip. A program reports its verdict by
// storing to the I/O port: 1 means pass, any other value is a failure code.
module tb_mips_top;

  localparam logic [7:0] PassCode = 8'd1;

  logic       clk = 1'b0;
  logic       rst_n = 1'b0;
  logic [7:0] io_port;

  initial forever #5 clk = ~clk;

  mips_top dut (
    .clk_i (clk),
    .rst_ni(rst_n),
    .io_o  (io_port)
  );

  string       program_hex;
  int unsigned max_cycles;

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
    if (!$value$plusargs("max_cycles=%d", max_cycles)) begin
      max_cycles = 10000;
    end
    $readmemh(program_hex, dut.u_sram.mem);

    repeat (2) @(posedge clk);
    rst_n = 1'b1;

    for (
        int unsigned cycle_count = 0; cycle_count < max_cycles && io_port == '0; cycle_count++
    ) begin
      @(posedge clk);
    end

    if (io_port == PassCode) begin
      $display("PASS %s", program_hex);
      $finish;
    end else if (io_port == '0) begin
      $fatal(1, "FAIL %s: no verdict after %0d cycles", program_hex, max_cycles);
    end else begin
      $fatal(1, "FAIL %s: check %0d failed", program_hex, io_port);
    end
  end

endmodule
