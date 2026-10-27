// The verdict a test program stores to the I/O port for tb_mips_top. Zero means
// it has not finished, PassCode means it passed, and any other value is the
// number of the check that failed.
package mips_test_pkg;

  parameter logic [mips_pkg::DataWidth-1:0] PassCode = 1;

endpackage
