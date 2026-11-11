`timescale 1ns / 1ps

module tb_EX_stage;

    // --- 1. Khai báo tín hiệu kích thích ngõ vào (reg) ---
    reg [31:0] pc_E;
    reg [31:0] rs1_data_E;
    reg [31:0] rs2_data_E;
    reg [31:0] imm_E;
    reg [4:0]  rd_addr_E;
    reg [15:0] execute_signals;

    // Tín hiệu đi tắt (Forwarding)
    reg [1:0]  forward_rs1;
    reg [1:0]  forward_rs2;
    reg [31:0] Result_M;
    reg [31:0] Result_W;

    // --- 2. Khai báo dây nối ngõ ra để quan sát (wire) ---
    wire [31:0] pc_plus4_E;
    wire [31:0] Result_E;
    wire [31:0] rs2_data_M_in;
    wire [4:0]  rd_addr_E_out;
    wire [15:0] memory_signals;

    // --- 3. Gọi module EX_stage cần test (UUT) ---
    EX_stage u_EX (
        .pc_E(pc_E),
        .rs1_data_E(rs1_data_E),
        .rs2_data_E(rs2_data_E),
        .imm_E(imm_E),
        .rd_addr_E(rd_addr_E),
        .execute_signals(execute_signals),
        .forward_rs1(forward_rs1),
        .forward_rs2(forward_rs2),
        .Result_M(Result_M),
        .Result_W(Result_W),
        
        .pc_plus4_E(pc_plus4_E),
        .Result_E(Result_E),
        .rs2_data_M_in(rs2_data_M_in),
        .rd_addr_E_out(rd_addr_E_out),
        .memory_signals(memory_signals)
    );

    // --- 4. Kịch bản kiểm tra logic tính toán ---
    initial begin
        // Khởi tạo giá trị mặc định ban đầu
        pc_E = 32'h0000_1000;
        rs1_data_E = 32'd100;       // rs1 = 100
        rs2_data_E = 32'd40;        // rs2 = 40
        imm_E = 32'd20;             // imm = 20
        rd_addr_E = 5'd5;
        forward_rs1 = 2'b00; forward_rs2 = 2'b00;
        Result_M = 32'd999;  Result_W = 32'd888;
        
        // Cài đặt bus execute_signals mặc định an toàn:
        // Bit[0]: op_b_sel (ALUSrc)
        // Bit[3]: is_pc
        // Bit[7:4]: alu_op
        execute_signals = 16'b0;

        #10;
        
        // ====================================================================
        // CASE 1: Test các phép tính toán cơ bản của ALU (Không có Hazard)
        // ====================================================================
        
        // Phép tính A: ADD lệnh R-type (ADD x5, xRA, xRB)
        // Mong đợi: operand_a = 100, operand_b = 40. Result_E = 140
        execute_signals[3]   = 1'b0;  // is_pc = 0
        execute_signals[0]   = 1'b0;  // op_b_sel = 0 (chọn rs2)
        execute_signals[7:4] = 4'b0000; // alu_op = ADD
        #10;

        // Phép tính B: SUB lệnh R-type
        // Mong đợi: Result_E = 100 - 40 = 60
        execute_signals[7:4] = 4'b0001; // alu_op = SUB
        #10;

        // Phép tính C: ADDI lệnh I-type (ADD dữ liệu với Immediate)
        // Mong đợi: operand_a = 100, operand_b = imm (20). Result_E = 120
        execute_signals[0]   = 1'b1;  // op_b_sel = 1 (chọn Imm)
        execute_signals[7:4] = 4'b0000; // alu_op = ADD
        #10;

        // Phép tính D: AND logic
        // Mong đợi: Result_E = 100 & 20 = 4
        execute_signals[7:4] = 4'b0010; // alu_op = AND
        #10;

        // ====================================================================
        // CASE 2: Test bộ tính toán Địa chỉ Đích rẽ nhánh (Target Address Gen)
        // ====================================================================
        // Mong đợi: pc_plus4_E = pc_E + imm_E = 32'h0000_1000 + 20 = 32'h0000_1014 (Hệ Hex)
        // (Xem trực tiếp tín hiệu pc_plus4_E trên xung xem ăn khớp không)

        // ====================================================================
        // CASE 3: Test MUX Xanh Lam (Data Forwarding từ tầng MEM và WB)
        // ====================================================================
        // Quay lại cấu hình lệnh ADD cơ bản (A + B)
        execute_signals[0]   = 1'b0;    // Chọn rs2
        execute_signals[7:4] = 4'b0000;  // Phép ADD
        
        // Tình huống Hazard 1: forward_rs1 = 2'b10 (Lấy dữ liệu đi tắt từ tầng MEM)
        // Mong đợi: toán hạng rs1 bị thay thế bằng Result_M (999). 
        // -> Result_E = 999 + 40 = 1039
        forward_rs1 = 2'b10;
        #10;

        // Tình huống Hazard 2: forward_rs2 = 2'b01 (Lấy dữ liệu đi tắt từ tầng WB)
        // Mong đợi: toán hạng rs2 bị thay thế bằng Result_W (888). 
        // -> Result_E = 999 + 888 = 1887
        // -> rs2_data_M_in phải chuyển thành 888 (để lưu xuống bộ nhớ nếu là lệnh Store)
        forward_rs2 = 2'b01;
        #10;

        // Reset lại đường Forwarding về bình thường
        forward_rs1 = 2'b00; forward_rs2 = 2'b00;
        #10;

        $finish;
    end

endmodule