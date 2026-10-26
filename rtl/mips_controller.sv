module mips_controller (
  input  logic                  clk_i,
  input  logic                  rst_ni,
  input  mips_pkg::instr_kind_e instr_kind_i,
  input  mips_pkg::alu_op_e     instr_alu_op_i,
  input  logic                  operands_equal_i,
  output mips_pkg::ctrl_t       ctrl_o
);

  import mips_pkg::*;

  // the SRAM answers a read on the clock edge after the request, so every
  // memory read takes two states: one to request, one to take the data
  typedef enum logic [3:0] {
    StFetch,
    StCaptureInstr,
    StDecode,
    StMemAddr,
    StLoadRequest,
    StLoadWriteback,
    StStore,
    StExecute,
    StAluWriteback,
    StBranch,
    StJump
  } state_e;

  state_e state_q, state_d;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q <= StFetch;
    end else begin
      state_q <= state_d;
    end
  end

  always_comb begin
    unique case (state_q)
      StFetch: state_d = StCaptureInstr;
      StCaptureInstr: state_d = StDecode;
      StDecode: begin
        unique case (instr_kind_i)
          InstrLoadByte, InstrStoreByte: state_d = StMemAddr;
          InstrAlu:                      state_d = StExecute;
          InstrBranchEqual:              state_d = StBranch;
          InstrJump:                     state_d = StJump;
          default:                       state_d = StFetch;
        endcase
      end
      StMemAddr: state_d = (instr_kind_i == InstrStoreByte) ? StStore : StLoadRequest;
      StLoadRequest: state_d = StLoadWriteback;
      StExecute: state_d = StAluWriteback;
      StLoadWriteback, StStore, StAluWriteback, StBranch, StJump: state_d = StFetch;
      default: state_d = StFetch;
    endcase
  end

  always_comb begin
    ctrl_o = '{
        mem_req: 1'b0,
        mem_write: 1'b0,
        mem_addr_sel: MemAddrPc,
        instr_write: 1'b0,
        pc_write: 1'b0,
        pc_sel: PcPlus4,
        operands_write: 1'b0,
        alu_op: AluAdd,
        alu_b_sel: AluBRegister,
        alu_result_write: 1'b0,
        rf_write: 1'b0,
        rf_write_sel: RfWriteAluResult
    };

    unique case (state_q)
      StFetch:        ctrl_o.mem_req = 1'b1;
      StCaptureInstr: begin
        ctrl_o.instr_write = 1'b1;
        ctrl_o.pc_write    = 1'b1;
      end
      StDecode:       ctrl_o.operands_write = 1'b1;
      StMemAddr: begin
        ctrl_o.alu_b_sel        = AluBImmediate;
        ctrl_o.alu_result_write = 1'b1;
      end
      StLoadRequest: begin
        ctrl_o.mem_req      = 1'b1;
        ctrl_o.mem_addr_sel = MemAddrData;
      end
      StLoadWriteback: begin
        ctrl_o.rf_write     = 1'b1;
        ctrl_o.rf_write_sel = RfWriteLoadByte;
      end
      StStore: begin
        ctrl_o.mem_req      = 1'b1;
        ctrl_o.mem_write    = 1'b1;
        ctrl_o.mem_addr_sel = MemAddrData;
      end
      StExecute: begin
        ctrl_o.alu_op           = instr_alu_op_i;
        ctrl_o.alu_result_write = 1'b1;
      end
      StAluWriteback: ctrl_o.rf_write = 1'b1;
      StBranch: begin
        ctrl_o.pc_write = operands_equal_i;
        ctrl_o.pc_sel   = PcBranchTarget;
      end
      StJump: begin
        ctrl_o.pc_write = 1'b1;
        ctrl_o.pc_sel   = PcJumpTarget;
      end
      default:        ;
    endcase
  end

endmodule
