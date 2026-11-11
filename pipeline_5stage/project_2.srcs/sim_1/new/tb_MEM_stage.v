`timescale 1ns / 1ps

module tb_MEM_stage;

    // Các cổng kích thích đầu vào của Testbench
    reg         clk;
    reg         reset;
    reg  [31:0] Result_M;
    reg  [31:0] rs2_data_M;
    reg  [4:0]  rd_addr_M;
    reg  [15:0] memory_signals_M;

    // Đường dây nối mạng tổ hợp tầng MEM
    wire [31:0] Result_M_out;
    wire [31:0] ld_data_M;
    wire [4:0]  rd_addr_M_out;
    wire [15:0] writeback_signals;

    // Đường dây ngõ ra cuối cùng sau khi chốt qua vách ngăn MEM/WB
    wire [31:0] Result_W;
    wire [31:0] ld_data_W;
    wire [4:0]  rd_addr_W;
    wire [15:0] writeback_signals_W;

    // 1. Gọi thực thể Tầng MEM (UUT1)
    MEM_stage u_MEM_stage (
        .clk(clk),
        .Result_M(Result_M), .rs2_data_M(rs2_data_M), .rd_addr_M(rd_addr_M), .memory_signals_M(memory_signals_M),
        .Result_M_out(Result_M_out), .ld_data_M(ld_data_M), .rd_addr_M_out(rd_addr_M_out), .writeback_signals(writeback_signals)
    );

    // 2. Gọi thực thể Thanh ghi phân tầng MEM/WB (UUT2)
    pipe_reg_MEM_WB u_pipe_reg_MEM_WB (
        .clk(clk), .reset(reset),
        .Result_M_out(Result_M_out), .ld_data_M(ld_data_M), .rd_addr_M_out(rd_addr_M_out), .writeback_signals(writeback_signals),
        .Result_W(Result_W), .ld_data_W(ld_data_W), .rd_addr_W(rd_addr_W), .writeback_signals_W(writeback_signals_W)
    );

    // Phát xung nhịp hệ thống chu kỳ T = 10ns
    always #5 clk = ~clk;

    initial begin
        // Giai đoạn 0: Khởi tạo trạng thái Reset hệ thống
        clk = 0; reset = 1;
        Result_M = 32'b0; rs2_data_M = 32'b0; rd_addr_M = 5'b0; memory_signals_M = 16'b0;
        #15 reset = 0; // Nhả reset sau 1.5 chu kỳ clock

        // --- TEST CASE 1: Mô phỏng lệnh Store Word (sw) ---
        // Ghi chuỗi dữ liệu đặc biệt `DEAD_BEEF` vào địa chỉ byte số 24 (tức ô nhớ Word số 6)
        Result_M = 32'd24; 
        rs2_data_M = 32'hDEAD_BEEF;
        rd_addr_M = 5'd0;                            // Lệnh SW không cần ghi về tập thanh ghi đích
        memory_signals_M = 16'b0000_0001_0000_0000;  // Bật bit [8] (MemWrite = 1)
        #10; // Đợi cạnh lên clock nạp dữ liệu ổn định vào RAM

        // --- TEST CASE 2: Mô phỏng lệnh Load Word (lw) đọc lại ô nhớ vừa ghi ---
        // Đọc dữ liệu từ địa chỉ byte số 24 để kiểm tra mạch logic
        Result_M = 32'd24;
        rd_addr_M = 5'd4;                            // Sau này dữ liệu sẽ được đưa về ghi vào thanh ghi x4
        memory_signals_M = 16'b0000_0010_0000_0100;  // Bật bit [9] (MemRead/is_load=1) và bit [2] (RegWrite=1)
        #10; // Khối tổ hợp ra dữ liệu ngay lập tức, cạnh lên tiếp theo chốt qua vách ngăn

        // --- TEST CASE 3: Mô phỏng Load Word tại vùng nhớ nạp sẵn ban đầu ---
        // Đọc từ địa chỉ byte số 40 (Word số 10) để xem có lấy ra đúng giá trị `5555_6666` không
        Result_M = 32'd40;
        rd_addr_M = 5'd5;                            // Dự kiến ghi về thanh ghi x5 ở tầng WB
        memory_signals_M = 16'b0000_0010_0000_0100;  // Giữ nguyên chế độ đọc bộ nhớ
        #15;
        
        $finish; // Kết thúc mô phỏng
    end

endmodule
