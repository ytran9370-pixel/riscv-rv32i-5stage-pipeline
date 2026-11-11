`timescale 1ns / 1ps

module pipe_reg_ID_EX (
    input  wire        clk,
    input  wire        reset,
    input  wire        flush,          // Nhận tín hiệu flush_ID_E từ Hazard Unit
 
    // Đầu vào từ tầng ID
    input  wire [31:0] pc_D,
    input  wire [31:0] rs1_data_D,     
    input  wire [31:0] rs2_data_D,     
    input  wire [31:0] imm_D,
    input  wire [4:0]  rd_addr_D,
    input  wire [15:0] decode_signals,
 
    // Đầu ra truyền sang tầng EX
    output reg  [31:0] pc_E,
    output reg  [31:0] rs1_data_E,
    output reg  [31:0] rs2_data_E,
    output reg  [31:0] imm_E,
    output reg  [4:0]  rd_addr_E,
    output reg  [15:0] execute_signals
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_E            <= 32'b0;
            rs1_data_E      <= 32'b0;
            rs2_data_E      <= 32'b0;
            imm_E           <= 32'b0;
            rd_addr_E       <= 5'b0;
            execute_signals <= 16'b0;
        end 
        else if (flush) begin
            // Khi bị flush (do Load-Use Hazard hoặc rẽ nhánh):
            // Giữ lại tuyến PC để dễ debug, nhưng đưa toàn bộ tín hiệu điều khiển 
            // và địa chỉ thanh ghi đích về 0 để triệt tiêu mọi khả năng ghi dữ liệu (tạo NOP)
            pc_E            <= pc_D;       
            rs1_data_E      <= 32'b0;
            rs2_data_E      <= 32'b0;
            imm_E           <= 32'b0;
            rd_addr_E       <= 5'b0;       
            execute_signals <= 16'b0;      // Tương đương với lệnh NOP
        end 
        else begin
            pc_E            <= pc_D;
            rs1_data_E      <= rs1_data_D;
            rs2_data_E      <= rs2_data_D;
            imm_E           <= imm_D;
            rd_addr_E       <= rd_addr_D;
            execute_signals <= decode_signals;
        end
    end

endmodule