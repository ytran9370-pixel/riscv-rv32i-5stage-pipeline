`timescale 1ns / 1ps

module CPU_Top (
    input wire clk,
    input wire reset
);

    // =========================================================================
    // 1. KHAI BÁO CÁC ĐƯỜNG DÂY TRUNG GIAN (WIRES) KẾT NỐI HỆ THỐNG
    // =========================================================================
 
    // --- Tầng IF (Instruction Fetch) ---
    wire [31:0] pc_F;
    wire [31:0] inst_F;
 
    // --- Đầu ra vách ngăn IF/ID (Đi vào tầng ID) ---
    wire [31:0] pc_D;
    wire [31:0] inst_D;
 
    // --- Tầng ID (Instruction Decode) ---
    wire [4:0]  rs1_addr_D;
    wire [4:0]  rs2_addr_D;
    wire [31:0] rs1_data_final;
    wire [31:0] rs2_data_final;
    wire [31:0] imm_D;
    wire [4:0]  rd_addr_D;
    wire [31:0] pc_out_D;
    wire [15:0] decode_signals;
 
    // --- Đầu ra vách ngăn ID/EX (Đi vào tầng EX) ---
    wire [31:0] pc_E;
    wire [31:0] rs1_data_E;
    wire [31:0] rs2_data_E;
    wire [31:0] imm_E;
    wire [4:0]  rd_addr_E;
    wire [15:0] execute_signals;
 
    // Đường chốt địa chỉ vật lý song song phục vụ riêng cho Hazard Unit tại tầng EX
    reg  [4:0]  rs1_addr_E;
    reg  [4:0]  rs2_addr_E;
 
    // --- Tầng EX (Execute) ---
    wire [31:0] pc_plus4_E;
    wire [31:0] Result_E;
    wire [31:0] rs2_data_M_in;
    wire [4:0]  rd_addr_E_out;
    wire [15:0] memory_signals;
 
    // --- Đầu ra vách ngăn EX/MEM (Đi vào tầng MEM) ---
    wire [31:0] Result_M;
    wire [31:0] rs2_data_M;
    wire [4:0]  rd_addr_M;
    wire [15:0] memory_signals_M;
 
    // --- Tầng MEM (Memory Access) ---
    wire [31:0] Result_M_out;
    wire [31:0] ld_data_M;
    wire [4:0]  rd_addr_M_out;
    wire [15:0] writeback_signals;
 
    // --- Đầu ra vách ngăn MEM/WB (Đi vào tầng WB) ---
    wire [31:0] Result_W;
    wire [31:0] ld_data_W;
    wire [4:0]  rd_addr_W;
    wire [15:0] writeback_signals_W;
 
    // --- Tầng WB (Writeback) ---
    wire [31:0] rd_data_W;
    wire [4:0]  rd_addr_W_out;
    wire        rd_wr_W;
 
    // --- Các tín hiệu điều phối từ Hazard Unit ---
    wire        stall_PC;       // Đóng băng bộ đếm PC độc lập
    wire        stall_IF_ID;    // Đóng băng vách ngăn IF/ID
    wire        flush_IF_ID;    // Xóa lệnh tầng IF/ID khi rẽ nhánh
    wire        flush_ID_E;     // Xóa điều khiển chèn NOP tầng ID/EX từ Hazard Unit
    wire [1:0]  forward_rs1;
    wire [1:0]  forward_rs2;
    wire [1:0]  forward_decode;
 
    // Tín hiệu chọn đường nhảy từ khối rẽ nhánh (Mặc định = 0, nối BRU nếu nâng cấp)
    wire branch_taken_E;
    wire branch_taken;
    assign branch_taken = branch_taken_E;

    // Gán tín hiệu xóa dựa theo trạng thái hệ thống
    assign flush_IF_ID = branch_taken;

    // =========================================================================
    // 2. LOGIC PHỤ: CHỐT ĐỊA CHỈ RS1/RS2 SANG TẦNG EX CHO HAZARD UNIT
    // =========================================================================
    // Đã đồng bộ hóa logic chốt địa chỉ đảm bảo tính nhất quán với vách ngăn ID/EX
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rs1_addr_E <= 5'b0;
            rs2_addr_E <= 5'b0;
        end else if (flush_ID_E) begin
            rs1_addr_E <= 5'b0;
            rs2_addr_E <= 5'b0;
        end else begin
            rs1_addr_E <= rs1_addr_D;
            rs2_addr_E <= rs2_addr_D;
        end
    end

    // =========================================================================
    // 3. KHỞI TẠO CÁC TẦNG THỰC THI VÀ CÁC THANH GHI VÁCH NGĂN
    // =========================================================================

    // --- [TẦNG 1: INSTRUCTION FETCH] ---
    // Nối tín hiệu stall_PC vào cổng stall để kiểm soát chính xác bộ đếm chương trình PC
    IF_stage u_IF_stage (
        .clk(clk),
        .reset(reset),
        .stall(stall_PC),
        .pc_plus4_E(pc_plus4_E),
        .branch_taken(branch_taken),
        .pc_F(pc_F),
        .inst_F(inst_F)
    );

    // --- [VÁCH NGĂN 1: IF/ID REGISTER] ---
    // Nối chính xác tín hiệu stall_IF_ID vào đây
    pipe_reg_IF_ID u_pipe_reg_IF_ID (
        .clk(clk),
        .reset(reset),
        .stall(stall_IF_ID),
        .flush(flush_IF_ID),
        .pc_F(pc_F),
        .inst_F(inst_F),
        .pc_D(pc_D),
        .inst_D(inst_D)
    );

    // --- [TẦNG 2: INSTRUCTION DECODE] ---
    ID_stage u_ID_stage (
        .clk(clk),
        .inst_D(inst_D),
        .pc_D(pc_D),
        .rd_addr_W(rd_addr_W_out),
        .rd_data_W(rd_data_W),
        .rd_wr_W(rd_wr_W),
        .forward_decode(forward_decode),
        .rs1_addr_D(rs1_addr_D),
        .rs2_addr_D(rs2_addr_D),
        .rs1_data_final(rs1_data_final),
        .rs2_data_final(rs2_data_final),
        .imm_D(imm_D),
        .rd_addr_D(rd_addr_D),
        .pc_out_D(pc_out_D),
        .decode_signals(decode_signals)
    );

    // --- [VÁCH NGĂN 2: ID/EX REGISTER] ---
    pipe_reg_ID_EX u_pipe_reg_ID_EX (
        .clk(clk),
        .reset(reset),
        .flush(flush_ID_E), 
        .pc_D(pc_out_D),
        .rs1_data_D(rs1_data_final),
        .rs2_data_D(rs2_data_final),
        .imm_D(imm_D),
        .rd_addr_D(rd_addr_D),
        .decode_signals(decode_signals),
        .pc_E(pc_E),
        .rs1_data_E(rs1_data_E),
        .rs2_data_E(rs2_data_E),
        .imm_E(imm_E),
        .rd_addr_E(rd_addr_E),
        .execute_signals(execute_signals)
    );

    // --- [TẦNG 3: EXECUTE] ---
    EX_stage u_EX_stage (
    .pc_E(pc_E), .rs1_data_E(rs1_data_E), .rs2_data_E(rs2_data_E),
    .imm_E(imm_E), .rd_addr_E(rd_addr_E), .execute_signals(execute_signals),
    .forward_rs1(forward_rs1), .forward_rs2(forward_rs2),
    .Result_M(Result_M), .Result_W(rd_data_W),
    .pc_plus4_E(pc_plus4_E), .Result_E(Result_E),
    .rs2_data_M_in(rs2_data_M_in), .rd_addr_E_out(rd_addr_E_out),
    .memory_signals(memory_signals),
    .branch_taken_E(branch_taken_E)          // <-- THÊM DÒNG NÀY
    );

    // --- [VÁCH NGĂN 3: EX/MEM REGISTER] ---
    pipe_reg_EX_MEM u_pipe_reg_EX_MEM (
        .clk(clk),
        .reset(reset),
        .Result_E(Result_E),
        .rs2_data_M_in(rs2_data_M_in),
        .rd_addr_E_out(rd_addr_E_out),
        .memory_signals(memory_signals),
        .Result_M(Result_M),
        .rs2_data_M(rs2_data_M),
        .rd_addr_M(rd_addr_M),
        .memory_signals_M(memory_signals_M)
    );

    // --- [TẦNG 4: MEMORY ACCESS] ---
    MEM_stage u_MEM_stage (
        .clk(clk),
        .Result_M(Result_M),
        .rs2_data_M(rs2_data_M),
        .rd_addr_M(rd_addr_M),
        .memory_signals_M(memory_signals_M),
        .Result_M_out(Result_M_out),
        .ld_data_M(ld_data_M),
        .rd_addr_M_out(rd_addr_M_out),
        .writeback_signals(writeback_signals)
    );

    // --- [VÁCH NGĂN 4: MEM/WB REGISTER] ---
    pipe_reg_MEM_WB u_pipe_reg_MEM_WB (
        .clk(clk),
        .reset(reset),
        .Result_M_out(Result_M_out),
        .ld_data_M(ld_data_M),
        .rd_addr_M_out(rd_addr_M_out),
        .writeback_signals(writeback_signals),
        .Result_W(Result_W),
        .ld_data_W(ld_data_W),
        .rd_addr_W(rd_addr_W),
        .writeback_signals_W(writeback_signals_W)
    );

    // --- [TẦNG 5: WRITEBACK] ---
    WB_stage u_WB_stage (
        .Result_W(Result_W),
        .ld_data_W(ld_data_W),
        .rd_addr_W(rd_addr_W),
        .writeback_signals_W(writeback_signals_W),
        .rd_data_W(rd_data_W),
        .rd_addr_W_out(rd_addr_W_out),
        .rd_wr_W(rd_wr_W)
    );

    // --- [KHỐI ĐIỀU PHỐI TRUNG TÂM: HAZARD UNIT] ---
    // Sửa lỗi: Bổ sung kết nối hoàn chỉnh cho stall_PC và branch_taken
    Hazard_Unit u_Hazard_Unit (
        .rs1_addr_D(rs1_addr_D),
        .rs2_addr_D(rs2_addr_D),
        .rs1_addr_E(rs1_addr_E),
        .rs2_addr_E(rs2_addr_E),
        .rd_addr_E(rd_addr_E),
        .rd_addr_M(rd_addr_M),
        .rd_addr_W(rd_addr_W_out),
        .execute_signals_E(execute_signals),
        .memory_signals_M(memory_signals_M),
        .writeback_signals_W(writeback_signals_W),
        .branch_taken(branch_taken),             // Nối ngõ vào rẽ nhánh để đồng bộ tín hiệu flush
        .stall_PC(stall_PC),                     // Nối tín hiệu điều khiển dừng PC
        .stall_IF_ID(stall_IF_ID),               // Nối tín hiệu điều khiển dừng vách ngăn IF/ID
        .flush_ID_E(flush_ID_E),  
        .forward_rs1(forward_rs1),
        .forward_rs2(forward_rs2),
        .forward_decode(forward_decode)
    ); 
endmodule