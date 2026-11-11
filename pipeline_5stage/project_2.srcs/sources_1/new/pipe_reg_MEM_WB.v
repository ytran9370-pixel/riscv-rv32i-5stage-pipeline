`timescale 1ns / 1ps

module pipe_reg_MEM_WB (
    input  wire        clk,
    input  wire        reset,
    
    // Ngõ vào từ rìa đầu ra của tầng MEM
    input  wire [31:0] Result_M_out,
    input  wire [31:0] ld_data_M,
    input  wire [4:0]  rd_addr_M_out,
    input  wire [15:0] writeback_signals,
    
    // Ngõ ra được chốt cố định cấp cho tầng WB ở chu kỳ sau
    output reg  [31:0] Result_W,
    output reg  [31:0] ld_data_W,
    output reg  [4:0]  rd_addr_W,
    output reg  [15:0] writeback_signals_W
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            Result_W            <= 32'b0;
            ld_data_W           <= 32'b0;
            rd_addr_W           <= 5'b0;
            writeback_signals_W <= 16'b0;
        end else begin
            Result_W            <= Result_M_out;
            ld_data_W           <= ld_data_M;
            rd_addr_W           <= rd_addr_M_out;
            writeback_signals_W <= writeback_signals;
        end
    end

endmodule