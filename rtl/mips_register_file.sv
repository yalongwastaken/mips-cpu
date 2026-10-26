module mips_register_file (
  input  logic                              clk_i,
  input  logic                              rst_ni,
  input  logic [mips_pkg::RegAddrWidth-1:0] read_addr_a_i,
  input  logic [mips_pkg::RegAddrWidth-1:0] read_addr_b_i,
  output logic [   mips_pkg::DataWidth-1:0] read_data_a_o,
  output logic [   mips_pkg::DataWidth-1:0] read_data_b_o,
  input  logic                              write_enable_i,
  input  logic [mips_pkg::RegAddrWidth-1:0] write_addr_i,
  input  logic [   mips_pkg::DataWidth-1:0] write_data_i
);

  import mips_pkg::*;

  localparam int unsigned NumRegs = 2 ** RegAddrWidth;

  logic [NumRegs-1:0][DataWidth-1:0] regs_q;

  // $0 is never written, so it reads as the zero it was reset to
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      regs_q <= '0;
    end else if (write_enable_i && write_addr_i != '0) begin
      regs_q[write_addr_i] <= write_data_i;
    end
  end

  assign read_data_a_o = regs_q[read_addr_a_i];
  assign read_data_b_o = regs_q[read_addr_b_i];

endmodule
