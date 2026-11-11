`timescale 1ns / 1ps

module tb_ID_stage;

    // --- 1. Khai báo các tín hiệu Kích thích ngõ vào (reg) ---
    reg         clk;
    reg [31:0]  inst_D;
    reg [31:0]  pc_D;
    
    // Tín hiệu từ tầng Writeback (WB)
    reg [4:0]   rd_addr_W;
    reg [31:0]  rd_data_W;
    reg         rd_wr_W;

    // Tín hiệu từ Hazard Unit
    reg [1:0]   forward_decode;

    // --- 2. Khai báo các dây nối Ngõ ra để quan sát (wire) ---
    wire [4:0]  rs1_addr_D;
    wire [4:0]  rs2_addr_D;
    wire [31:0] rs1_data_final;
    wire [31:0] rs2_data_final;
    wire [31:0] imm_D;
    wire [4:0]  rd_addr_D;
    wire [31:0] pc_out_D;
    wire [15:0] decode_signals;

    // --- 3. Gọi chính xác module ID_stage cần test (UUT) ---
    ID_stage u_ID (
        .clk(clk),
        .inst_D(inst_D),
        .pc_D(pc_D),
        .rd_addr_W(rd_addr_W),
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

    // --- 4. Tạo xung Clock chu kỳ 10ns ---
    always begin
        #5 clk = ~clk;
    end

    // --- 5. Kịch bản chạy Testbench ---
    initial begin
        // Khởi tạo các giá trị ban đầu
        clk = 0;
        pc_D = 32'h0000_0000;
        inst_D = 32'h0000_0013;       // Lệnh mặc định ban đầu là NOP (addi x0, x0, 0)
        forward_decode = 2'b00;       // Mặc định lấy dữ liệu trực tiếp từ RegFile
        rd_wr_W = 0; rd_addr_W = 5'd0; rd_data_W = 32'h0;

        // Đợi 2 chu kỳ clock hệ thống ổn định
        #20;
        
        // ====================================================================
        // GIAI ĐOẠN 1: GHI GIẢ LẬP DỮ LIỆU VÀO THANH GHI (Thông qua đường WB)
        // Vì RegFile ban đầu bằng 0, ta cần nạp giá trị vào x10 và x11 để lát nữa test đọc
        // ====================================================================
        @(negedge clk);
        rd_wr_W = 1; rd_addr_W = 5'd10; rd_data_W = 32'hAAAA_BBBB; // Ghi vào x10
        
        @(negedge clk);
        rd_wr_W = 1; rd_addr_W = 5'd11; rd_data_W = 32'h1111_2222; // Ghi vào x11
        
        @(negedge clk);
        rd_wr_W = 0; // Tắt tín hiệu ghi để chuẩn bị test Giải mã lệnh

        // ====================================================================
        // GIAI ĐOẠN 2: TEST GIẢI MÃ LỆNH & ĐỌC THANH GHI
        // ====================================================================
        
        // --- Lệnh 1: ADDI x12, x10, 255 (Mã máy I-type: 0ff50613) ---
        // Phân tích mong đợi: 
        // -> rs1_addr_D = 10, rs2_addr_D = 0 (đã ép về 0 cho lệnh I-type trong code của bạn)
        // -> rd_addr_D = 12, imm_D = 32'h0000_00ff
        // -> decode_signals[0] (ALUSrc) = 1, decode_signals[2] (RegWrite) = 1
        // -> rs1_data_final = 32'hAAAA_BBBB
        @(negedge clk);
        pc_D   = 32'h0000_0004;
        inst_D = 32'h0ff5_0613; 

        // --- Lệnh 2: ADD x13, x10, x11 (Mã máy R-type: 00b506b3) ---
        // Phân tích mong đợi:
        // -> rs1_addr_D = 10, rs2_addr_D = 11, rd_addr_D = 13, imm_D = 0
        // -> decode_signals[0] (ALUSrc) = 0, decode_signals[2] (RegWrite) = 1
        // -> rs1_data_final = 32'hAAAA_BBBB, rs2_data_final = 32'h1111_2222
        #10;
        @(negedge clk);
        pc_D   = 32'h0000_0008;
        inst_D = 32'h00b5_06b3;

        // --- Lệnh 3: LW x14, 8(x10) (Mã máy I-type Load: 00852703) ---
        // Phân tích mong đợi:
        // -> rs1_addr_D = 10, rd_addr_D = 14, imm_D = 8
        // -> decode_signals[1] (is_load) = 1, decode_signals[9] (mem_read) = 1
        #10;
        @(negedge clk);
        pc_D   = 32'h0000_000C;
        inst_D = 32'h0085_2703;

        // ====================================================================
        // GIAI ĐOẠN 3: TEST MUX ĐỎ (EARLY FORWARDING TỪ TẦNG WB)
        // ====================================================================
        // Tình huống: Lệnh trước đó vừa ghi vào x10 ở tầng WB, nhưng lệnh hiện tại 
        // tại tầng ID cũng đang cần đọc x10 gấp -> Hazard Unit bật forward_decode.
        
        #10;
        @(negedge clk);
        inst_D = 32'h00b5_06b3;       // Lệnh ADD x13, x10, x11
        rd_data_W = 32'h5555_6666;    // Giá trị mới tinh từ tầng WB cấp về
        forward_decode = 2'b01;       // Bật bộ chọn MUX đỏ cho rs1
        
        // Phân tích mong đợi:
        // -> rs1_data_final phải ăn theo giá trị từ đường forward (32'h5555_6666)
        // -> rs2_data_final vẫn lấy từ RegFile bình thường (32'h1111_2222)

        // Kết thúc xem sóng
        #20;
        $finish;
    end

endmodule