`timescale 1ns / 1ps

module EX_stage (
    input  wire [31:0] pc_E,
    input  wire [31:0] rs1_data_E,
    input  wire [31:0] rs2_data_E,
    input  wire [31:0] imm_E,
    input  wire [4:0]  rd_addr_E,
    input  wire [15:0] execute_signals,

    input  wire [1:0]  forward_rs1,
    input  wire [1:0]  forward_rs2,
    input  wire [31:0] Result_M,
    input  wire [31:0] Result_W,

    output wire [31:0] pc_plus4_E,
    output wire [31:0] Result_E,
    output wire [31:0] rs2_data_M_in,
    output wire [4:0]  rd_addr_E_out,
    output wire [15:0] memory_signals,
    output wire        branch_taken_E     // <-- CỔNG MỚI, cần khai báo thêm ở CPU_Top.v
);
    wire        is_branch   = execute_signals[3];
    wire        branch_type = execute_signals[10];
    wire        op_b_sel    = execute_signals[0];
    wire [3:0]  alu_op      = execute_signals[7:4];

    assign pc_plus4_E = pc_E + imm_E;

    wire [31:0] rs1_forwarded;
    assign rs1_forwarded = (forward_rs1 == 2'b10) ? Result_M :
                           (forward_rs1 == 2'b01) ? Result_W : rs1_data_E;
    wire [31:0] rs2_forwarded;
    assign rs2_forwarded = (forward_rs2 == 2'b10) ? Result_M :
                           (forward_rs2 == 2'b01) ? Result_W : rs2_data_E;
    assign rs2_data_M_in = rs2_forwarded;

    wire [31:0] operand_a;
    assign operand_a = rs1_forwarded;

    wire [31:0] operand_b;
    assign operand_b = (op_b_sel) ? imm_E : rs2_forwarded;

    reg [31:0] alu_result_reg;
    always @(*) begin
        case (alu_op)
            4'b0000: alu_result_reg = operand_a + operand_b;
            4'b0001: alu_result_reg = operand_a - operand_b;
            4'b0010: alu_result_reg = operand_a & operand_b;
            4'b0011: alu_result_reg = operand_a | operand_b;
            4'b0100: alu_result_reg = operand_a ^ operand_b;
            default: alu_result_reg = operand_a + operand_b;
        endcase
    end

    wire br_equal = (rs1_forwarded == rs2_forwarded);
    assign branch_taken_E = is_branch && (branch_type ? ~br_equal : br_equal);

    assign Result_E       = alu_result_reg;
    assign rd_addr_E_out  = rd_addr_E;
    assign memory_signals = execute_signals;
endmodule