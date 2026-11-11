`timescale 1ns / 1ps

module Reg_File (
    input  wire        clk,
    input  wire [4:0]  rs1_addr,    // Địa chỉ đọc rs1
    input  wire [4:0]  rs2_addr,    // Địa chỉ đọc rs2
    input  wire [4:0]  rd_addr_W,   // Địa chỉ ghi rd (từ tầng WB)
    input  wire [31:0] rd_data_W,   // Dữ liệu ghi (từ tầng WB)
    input  wire        rd_wr_W,     // Tín hiệu cho phép ghi (từ tầng WB)
    
    output wire [31:0] rs1_data,    // Dữ liệu đọc ra 1
    output wire [31:0] rs2_data     // Dữ liệu đọc ra 2
);
    reg [31:0] registers [31:0];
    integer i;

    // Khởi tạo 32 thanh ghi bằng 0
    initial begin
        for (i = 0; i < 32; i = i + 1) registers[i] = 32'b0;
    end

    // Ghi dữ liệu vào thanh ghi (Ghi vào cạnh lên hoặc xuống tùy thiết kế, 
    // ở đây chọn cạnh lên đồng bộ theo sơ đồ có tam giác)
    always @(posedge clk) begin
        if (rd_wr_W && (rd_addr_W != 5'b0)) begin
            registers[rd_addr_W] <= rd_data_W;
        end
    end

    // Đọc dữ liệu (Mạch tổ hợp)
    // Thanh ghi x0 luôn luôn trả về 0
    assign rs1_data = (rs1_addr == 5'b0) ? 32'b0 : registers[rs1_addr];
    assign rs2_data = (rs2_addr == 5'b0) ? 32'b0 : registers[rs2_addr];

endmodule