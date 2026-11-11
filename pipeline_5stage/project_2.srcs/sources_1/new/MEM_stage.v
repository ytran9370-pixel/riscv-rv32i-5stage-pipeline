`timescale 1ns / 1ps

module MEM_stage (
    input  wire        clk,
    
    // Tín hiệu ngõ vào nhận từ vách ngăn EX/MEM
    input  wire [31:0] Result_M,           // Địa chỉ truy xuất bộ nhớ (từ ALU)
    input  wire [31:0] rs2_data_M,         // Dữ liệu thô chuẩn bị ghi vào RAM (từ rs2)
    input  wire [4:0]  rd_addr_M,          // Địa chỉ thanh ghi đích rd
    input  wire [15:0] memory_signals_M,   // Bus tập hợp tín hiệu điều khiển tầng MEM
    
    // Các ngõ ra truyền tới vách ngăn tiếp theo (MEM/WB)
    output wire [31:0] Result_M_out,       // Đường truyền thẳng địa chỉ/kết quả ALU sang tầng WB
    output wire [31:0] ld_data_M,          // Dữ liệu đọc ra từ khối LSU
    output wire [4:0]  rd_addr_M_out,      // Địa chỉ rd truyền tiếp
    output wire [15:0] writeback_signals   // Bus điều khiển truyền tiếp phục vụ tầng WB
);

    // Bóc tách các tín hiệu điều khiển bộ nhớ từ bus chung
    wire mem_write = memory_signals_M[8]; // Lệnh Store (sw) bật bit này bằng 1
    wire mem_read  = memory_signals_M[9]; // Lệnh Load (lw) bật bit này bằng 1

    // Khối cấu trúc RAM Dữ liệu mẫu (Data Memory Mock - 64 từ 32-bit)
    reg [31:0] data_mem [63:0];
    integer i;
    
    // Khởi tạo vùng nhớ ban đầu để phục vụ mô phỏng
    initial begin
        for(i = 0; i < 64; i = i + 1) begin
            data_mem[i] = 32'b0;
        end
        // Nạp sẵn một vài hằng số tại địa chỉ cố định để test mạch đọc (Load)
        data_mem[10] = 32'h5555_6666; // Word thứ 10 (tương ứng byte address = 40)
    end

    // Mạch ghi dữ liệu vào RAM (Đồng bộ theo cạnh lên xung nhịp hệ thống)
    always @(posedge clk) begin
        if (mem_write) begin
            // Dịch phải 2 bit (chia 4) để chuyển đổi từ địa chỉ Byte sang địa chỉ Word của mảng
            data_mem[Result_M[7:2]] <= rs2_data_M;
        end
    end

    // Mạch đọc dữ liệu từ RAM (Mạch tổ hợp xuất dữ liệu tức thời ra cổng ld_data_M)
    assign ld_data_M = (mem_read) ? data_mem[Result_M[7:2]] : 32'b0;

    // Ánh xạ kết nối các đường dây đi thẳng vượt cấp tầng MEM
    assign Result_M_out      = Result_M;
    assign rd_addr_M_out     = rd_addr_M;
    assign writeback_signals = memory_signals_M;

endmodule