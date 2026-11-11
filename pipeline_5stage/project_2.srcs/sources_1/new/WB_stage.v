`timescale 1ns / 1ps

module WB_stage (
    // Tín hiệu ngõ vào nhận từ vách ngăn MEM/WB
    input  wire [31:0] Result_W,            // Kết quả từ ALU chốt từ tầng trước
    input  wire [31:0] ld_data_W,           // Dữ liệu đọc từ bộ nhớ chốt từ tầng trước
    input  wire [4:0]  rd_addr_W,           // Địa chỉ thanh ghi đích rd
    input  wire [15:0] writeback_signals_W, // Bus tín hiệu điều khiển tầng WB
    
    // Các ngõ ra quay ngược về tầng ID (để đưa vào Register File)
    output wire [31:0] rd_data_W,           // Dữ liệu thực tế ghi về thanh ghi
    output wire [4:0]  rd_addr_W_out,       // Địa chỉ thanh ghi đích truyền trả về ID
    output wire        rd_wr_W              // Tín hiệu cho phép ghi tập thanh ghi (RegWrite)
);

    // Bóc tách tín hiệu điều khiển dựa theo cấu trúc phần cứng trong sơ đồ khối
    // Giả định quy ước: 
    // Bit [9] tương ứng với is_load_W (1: Chọn dữ liệu từ RAM, 0: Chọn dữ liệu từ ALU)
    // Bit [2] tương ứng với rd_wr_W (1: Cho phép ghi về thanh ghi, 0: Không ghi)
    wire is_load_W = writeback_signals_W[9];
    assign rd_wr_W = writeback_signals_W[2];

    // MUX tổ hợp chọn nguồn dữ liệu ghi về thanh ghi rd
    assign rd_data_W = (is_load_W) ? ld_data_W : Result_W;

    // Truyền thẳng địa chỉ thanh ghi đích về lại tầng ID
    assign rd_addr_W_out = rd_addr_W;

endmodule