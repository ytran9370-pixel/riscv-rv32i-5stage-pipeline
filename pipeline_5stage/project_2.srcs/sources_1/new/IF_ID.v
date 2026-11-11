`timescale 1ns / 1ps

module pipe_reg_IF_ID (
    input  wire        clk,
    input  wire        reset,
    input  wire        stall,      // Nhận tín hiệu stall_IF_ID từ Hazard Unit
    input  wire        flush,      // Nhận tín hiệu flush từ hệ thống (nếu có)
 
    input  wire [31:0] pc_F,       
    input  wire [31:0] inst_F,     
 
    output reg  [31:0] pc_D,       
    output reg  [31:0] inst_D      
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_D   <= 32'h0000_0000;
            inst_D <= 32'h0000_0013; // Mặc định reset ra lệnh NOP (addi x0, x0, 0)
        end
        else if (flush) begin
            pc_D   <= 32'h0000_0000;
            inst_D <= 32'h0000_0013; // Ép thành NOP khi bị flush
        end
        else if (!stall) begin
            pc_D   <= pc_F;
            inst_D <= inst_F;
        end
        // Nếu stall == 1: pc_D và inst_D giữ nguyên giá trị (bị đóng băng)
    end

endmodule