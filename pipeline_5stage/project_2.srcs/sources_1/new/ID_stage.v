`timescale 1ns / 1ps

module ID_stage (
    input  wire        clk,
    input  wire [31:0] inst_D,
    input  wire [31:0] pc_D,
    input  wire [4:0]  rd_addr_W,
    input  wire [31:0] rd_data_W,
    input  wire   rd_wr_W,
    input  wire [1:0]  forward_decode,
    output wire [4:0]  rs1_addr_D,
    output wire [4:0]  rs2_addr_D,
    output wire [31:0] rs1_data_final,
    output wire [31:0] rs2_data_final,
    output reg  [31:0] imm_D,
    output wire [4:0]  rd_addr_D,
    output wire [31:0] pc_out_D,
    output reg  [15:0] decode_signals
);

    wire [6:0] opcode = inst_D[6:0];
    wire [2:0] funct3 = inst_D[14:12];
    wire [6:0] funct7 = inst_D[31:25];

    assign rs1_addr_D = inst_D[19:15];
    assign rd_addr_D  = inst_D[11:7];
    assign pc_out_D   = pc_D;

    assign rs2_addr_D = (opcode == 7'h33 || opcode == 7'h63 || opcode == 7'h23) ? inst_D[24:20] : 5'b0;

    always @(*) begin
        case (opcode)
            7'h13:   imm_D = {{20{inst_D[31]}}, inst_D[31:20]};
            7'h03:   imm_D = {{20{inst_D[31]}}, inst_D[31:20]};
            7'h23:   imm_D = {{20{inst_D[31]}}, inst_D[31:25], inst_D[11:7]};
            7'h63:   imm_D = {{20{inst_D[31]}}, inst_D[7], inst_D[30:25], inst_D[11:8], 1'b0};
            default: imm_D = 32'b0;
        endcase
    end

    wire [31:0] rs1_raw, rs2_raw;
    Reg_File u_reg_file (
        .clk(clk), .rs1_addr(rs1_addr_D), .rs2_addr(rs2_addr_D),
        .rd_addr_W(rd_addr_W), .rd_data_W(rd_data_W), .rd_wr_W(rd_wr_W),
        .rs1_data(rs1_raw), .rs2_data(rs2_raw)
    );

    assign rs1_data_final = (forward_decode[0]) ? rd_data_W : rs1_raw;
    assign rs2_data_final = (forward_decode[1]) ? rd_data_W : rs2_raw;

    // =========================================================================
    // BỘ GIẢI MÃ ĐIỀU KHIỂN
    // decode_signals[0]  : ALUSrc
    // decode_signals[1]  : is_load
    // decode_signals[2]  : RegWrite
    // decode_signals[3]  : is_branch (lệnh rẽ nhánh có điều kiện)
    // decode_signals[7:4]: alu_op        <-- MỚI GÁN cho R-type (SUB/AND/OR/XOR)
    // decode_signals[8]  : mem_write
    // decode_signals[9]  : mem_read
    // decode_signals[10] : branch_type (0=beq, 1=bne)   <-- MỚI THÊM
    // =========================================================================
    always @(*) begin
        decode_signals = 16'b0;

        case (opcode)
            7'h33: begin // R-type: add/sub/and/or/xor
                decode_signals[0] = 1'b0;
                decode_signals[2] = 1'b1;
                case ({funct7[5], funct3})
                    4'b0_000: decode_signals[7:4] = 4'b0000; // add
                    4'b1_000: decode_signals[7:4] = 4'b0001; // sub
                    4'b0_111: decode_signals[7:4] = 4'b0010; // and
                    4'b0_110: decode_signals[7:4] = 4'b0011; // or
                    4'b0_100: decode_signals[7:4] = 4'b0100; // xor
                    default:  decode_signals[7:4] = 4'b0000;
                endcase
            end
            7'h13: begin // I-type: addi
                decode_signals[0] = 1'b1;
                decode_signals[2] = 1'b1;
                decode_signals[7:4] = 4'b0000;
            end
            7'h03: begin // Load: lw
                decode_signals[0] = 1'b1;
                decode_signals[1] = 1'b1;
                decode_signals[2] = 1'b1;
                decode_signals[9] = 1'b1;
                decode_signals[7:4] = 4'b0000;
            end
            7'h23: begin // Store: sw
                decode_signals[0] = 1'b1;
                decode_signals[2] = 1'b0;
                decode_signals[8] = 1'b1;
                decode_signals[7:4] = 4'b0000;
            end
            7'h63: begin // Branch: beq/bne
                decode_signals[0] = 1'b0;
                decode_signals[2] = 1'b0;
                decode_signals[3] = 1'b1;
                decode_signals[10] = funct3[0]; // 0 = beq, 1 = bne
            end
            default: begin
                decode_signals = 16'b0;
            end
        endcase
    end

endmodule