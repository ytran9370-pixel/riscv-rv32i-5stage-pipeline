`timescale 1ns / 1ps

module pipe_reg_EX_MEM (
    input  wire        clk,
    input  wire        reset,
    
    // Ngõ vào từ tầng EX
    input  wire [31:0] Result_E,
    input  wire [31:0] rs2_data_M_in,
    input  wire [4:0]  rd_addr_E_out,
    input  wire [15:0] memory_signals,
    
    // Ngõ ra chốt sang tầng MEM
    output reg  [31:0] Result_M,
    output reg  [31:0] rs2_data_M,
    output reg  [4:0]  rd_addr_M,
    output reg  [15:0] memory_signals_M
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            Result_M         <= 32'b0;
            rs2_data_M       <= 32'b0;
            rd_addr_M        <= 5'b0;
            memory_signals_M <= 16'b0;
        end else begin
            Result_M         <= Result_E;
            rs2_data_M       <= rs2_data_M_in;
            rd_addr_M        <= rd_addr_E_out;
            memory_signals_M <= memory_signals;
        end
    end

endmodule