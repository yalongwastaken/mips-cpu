// Writes the package constants the test programs and their linker script share
// with the chip and tb_mips_top, so neither side keeps its own copy. Each line is
// `NAME = value;`, which GNU as and GNU ld both read as a symbol assignment.
module export_package_constants;
  import mips_pkg::*;
  import mips_test_pkg::*;

  initial begin
    string constants_path;
    int    constants_file;

    if (!$value$plusargs("constants=%s", constants_path)) begin
      $fatal(1, "missing +constants=<path>");
    end
    constants_file = $fopen(constants_path, "w");
    // $fopen fails only by returning 0, and writes to 0 vanish silently
    if (constants_file == 0) begin
      $fatal(1, "cannot write %s", constants_path);
    end
    $fwrite(constants_file, "RESET_PC = 0x%0h;\n", ResetPc);
    $fwrite(constants_file, "MEMORY_BYTES = %0d;\n", MemWordCount * MemBytesPerWord);
    $fwrite(constants_file, "DATA_REACH_BYTES = %0d;\n", 2 ** DataWidth);
    $fwrite(constants_file, "IO_PORT_ADDR = 0x%0h;\n", IoPortAddr);
    $fwrite(constants_file, "PASS_CODE = %0d;\n", PassCode);
    $fclose(constants_file);
    $finish;
  end

endmodule
