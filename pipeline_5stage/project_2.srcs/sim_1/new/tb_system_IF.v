`timescale 1ns / 1ps

module tb_system_IF;

    // Tín hiệu điều khiển (Kích thích ngõ vào)
    reg         clk;
    reg         reset;
    reg         stall;
    reg         flush;
    reg  [31:0] pc_plus4_E;
    reg         branch_taken;

    // Dây nối nội bộ giữa Tầng IF và Thanh ghi phân tầng
    wire [31:0] pc_F_net;
    wire [31:0] inst_F_net;

    // Ngõ ra cuối cùng truyền sang tầng ID
    wire [31:0] pc_D;
    wire [31:0] inst_D;

    // 1. Gọi tầng IF cần test
    IF_stage u_IF (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .pc_plus4_E(pc_plus4_E),
        .branch_taken(branch_taken),
        .pc_F(pc_F_net),
        .inst_F(inst_F_net)
    );

    // 2. Gọi Thanh ghi phân tầng IF/ID
    pipe_reg_IF_ID u_pipe_IF_ID (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .flush(flush),
        .pc_F(pc_F_net),
        .inst_F(inst_F_net),
        .pc_D(pc_D),
        .inst_D(inst_D)
    );

    // Tạo xung Clock Chu kỳ 10ns (Cạnh lên tại 5ns, 15ns, 25ns,...)
    always begin
        #5 clk = ~clk;
    end

    // Kịch bản test độc lập, loại bỏ Stall
    initial begin
        // --- Chu kỳ 0: Khởi tạo hệ thống ---
        clk = 0; 
        reset = 1; 
        stall = 0;          // Cố định stall = 0 để né lỗi stall
        flush = 0;
        pc_plus4_E = 32'h0000_0000; 
        branch_taken = 0;
        
        // --- Chu kỳ 1: Giữ reset hoạt động một khoảng thời gian ---
        #10; 
        
        // --- Chu kỳ 2: Giải phóng reset tại cạnh xuống clock để an toàn ---
        @(negedge clk);
        reset = 0;          // Kể từ đây PC bắt đầu chạy từ 32'h0
        
        // --- Chu kỳ 3->5: Chạy tuần tự (PC = 0 -> 4 -> 8 -> C) ---
        // Cho mạch tự động cộng PC+4 qua mỗi chu kỳ clock
        #30; 
        
        // --- Chu kỳ 6: Test tính năng Rẽ Nhánh (Branch Taken) ---
        // Giả sử lệnh tại tầng EX tính toán xong và yêu cầu nhảy về địa chỉ 4096 (32'h0000_1000)
        @(negedge clk);
        pc_plus4_E = 32'h0000_1000; 
        branch_taken = 1; 
        
        // --- Chu kỳ 7: Nhả tín hiệu Branch ---
        // Sau 1 chu kỳ ép nhảy, ta phải tắt branch_taken để PC tiếp tục cộng +4 từ địa chỉ mới
        @(negedge clk);
        branch_taken = 0;   // Lúc này PC hiện tại sẽ ăn giá trị 32'h1000, và chu kỳ sau sẽ là 32'h1004
        
        // --- Chu kỳ 8: Chạy tuần tự tại vùng địa chỉ mới ---
        #10;
        
        // --- Chu kỳ 9: Test tính năng Flush (Xóa lệnh tầng IF/ID) ---
        @(negedge clk);
        flush = 1; 
        
        // --- Chu kỳ 10: Tắt Flush và kết thúc mô phỏng ---
        @(negedge clk);
        flush = 0;
        #20;

        $finish;
    end

endmodule