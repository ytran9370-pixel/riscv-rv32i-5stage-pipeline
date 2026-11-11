`timescale 1ns / 1ps

module tb_WB_stage;

    // Các cổng kích thích đầu vào của Testbench
    reg [31:0] Result_W;
    reg [31:0] ld_data_W;
    reg [4:0]  rd_addr_W;
    reg [15:0] writeback_signals_W;

    // Các đường dây ngõ ra kiểm tra
    wire [31:0] rd_data_W;
    wire [4:0]  rd_addr_W_out;
    wire        rd_wr_W;

    // Gọi thực thể tầng WB (Unit Under Test)
    WB_stage uut (
        .Result_W(Result_W),
        .ld_data_W(ld_data_W),
        .rd_addr_W(rd_addr_W),
        .writeback_signals_W(writeback_signals_W),
        .rd_data_W(rd_data_W),
        .rd_addr_W_out(rd_addr_W_out),
        .rd_wr_W(rd_wr_W)
    );

    initial begin
        // Khởi tạo ban đầu
        Result_W = 32'b0;
        ld_data_W = 32'b0;
        rd_addr_W = 5'b0;
        writeback_signals_W = 16'b0;
        #10;

        // --- TEST CASE 1: Mô phỏng lệnh ALU (Ví dụ: ADD, SUB) ---
        // Kết quả tính toán ALU là `32'h0000_002A` (Số 42), đích ghi về thanh ghi x5 (rd = 5)
        // Cấu hình: is_load_W = 0, rd_wr_W = 1 -> writeback_signals_W = 16'h0004
        Result_W = 32'h0000_002A;
        ld_data_W = 32'hAAAA_BBBB; // Dữ liệu rác từ RAM
        rd_addr_W = 5'd5;
        writeback_signals_W = 16'b0000_0000_0000_0100; // Bit [2] = 1
        #20;
        // Kiểm tra mong đợi: rd_data_W phải ra 32'h0000_002A, rd_wr_W = 1, rd_addr_W_out = 5

        // --- TEST CASE 2: Mô phỏng lệnh Load Word (lw) ---
        // Dữ liệu đọc từ bộ nhớ RAM là `32'hDEAD_BEEF`, đích ghi về thanh ghi x12 (rd = 12)
        // Cấu hình: is_load_W = 1, rd_wr_W = 1 -> writeback_signals_W = 16'h0204
        Result_W = 32'h0000_0080; // Địa chỉ RAM (không lấy giá trị này)
        ld_data_W = 32'hDEAD_BEEF;
        rd_addr_W = 5'd12;
        writeback_signals_W = 16'b0000_0010_0000_0100; // Bit [9] = 1, Bit [2] = 1
        #20;
        // Kiểm tra mong đợi: rd_data_W phải chọn 32'hDEAD_BEEF, rd_wr_W = 1, rd_addr_W_out = 12

        // --- TEST CASE 3: Mô phỏng lệnh không ghi về tập thanh ghi (Ví dụ: SW, BEQ) ---
        // Cấu hình: rd_wr_W = 0 -> writeback_signals_W = 16'h0000
        Result_W = 32'h0000_0010;
        ld_data_W = 32'hZZZZ_ZZZZ;
        rd_addr_W = 5'd0;
        writeback_signals_W = 16'b0000_0000_0000_0000; // Tất cả bằng 0
        #20;
        // Kiểm tra mong đợi: rd_wr_W = 0 (khóa cổng ghi tại Register File)

        $finish;
    end

endmodule