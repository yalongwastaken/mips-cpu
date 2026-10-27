// The verdict a test program reports to tb_mips_top on the I/O port, which reads
// zero until then. A program passes by storing PassCode and then zero, and fails
// by storing the number of the check that failed and stopping.
package mips_test_pkg;

  parameter logic [mips_pkg::DataWidth-1:0] PassCode = 1;

endpackage
