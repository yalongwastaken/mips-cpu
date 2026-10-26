module mips_ram (
  input  logic                                  clk_i,
  input  logic                                  req_i,
  input  logic                                  write_i,
  input  logic [mips_pkg::MemWordAddrWidth-1:0] word_addr_i,
  input  logic [ mips_pkg::MemBytesPerWord-1:0] byte_enable_i,
  input  logic [    mips_pkg::MemWordWidth-1:0] write_data_i,
  output logic [    mips_pkg::MemWordWidth-1:0] read_data_o
);

  import mips_pkg::*;

  // no reset, as in an SRAM: a word holds whatever was loaded or stored there
  logic [MemWordWidth-1:0] memory_words[MemWordCount];

  always_ff @(posedge clk_i) begin
    if (req_i) begin
      if (write_i) begin
        for (int unsigned byte_index = 0; byte_index < MemBytesPerWord; byte_index++) begin
          if (byte_enable_i[byte_index]) begin
            memory_words[word_addr_i][byte_index*DataWidth+:DataWidth] <=
                write_data_i[byte_index*DataWidth+:DataWidth];
          end
        end
      end else begin
        read_data_o <= memory_words[word_addr_i];
      end
    end
  end

endmodule
