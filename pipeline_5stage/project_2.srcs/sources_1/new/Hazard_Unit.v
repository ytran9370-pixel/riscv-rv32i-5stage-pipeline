`timescale 1ns / 1ps

module Hazard_Unit (
    // 1. Địa chỉ thanh ghi từ tầng ID (Decode)
    input wire [4:0]  rs1_addr_D,
    input wire [4:0]  rs2_addr_D,
    
    // 2. Tín hiệu từ tầng EX (Execute)
    input wire [4:0]  rs1_addr_E,       
    input wire [4:0]  rs2_addr_E,       
    input wire [4:0]  rd_addr_E,
    input wire [15:0] execute_signals_E,    // Nhận trực tiếp bus điều khiển EX từ CPU_Top

    // 3. Tín hiệu từ tầng MEM (Memory Access)
    input wire [4:0]  rd_addr_M,
    input wire [15:0] memory_signals_M,     // Nhận trực tiếp bus điều khiển MEM từ CPU_Top
    
    // 4. Tín hiệu từ tầng WB (Writeback)
    input wire [4:0]  rd_addr_W,
    input wire [15:0] writeback_signals_W,  // Nhận trực tiếp bus điều khiển WB từ CPU_Top
    
    // 5. Khối Rẽ nhánh (BRU)
    input wire        branch_taken,      

    // --- CÁC NGÕ RA ĐIỀU KHIỂN ---
    output reg [1:0]  forward_rs1,       
    output reg [1:0]  forward_rs2,       
    output reg [1:0]  forward_decode,    
    
    output wire       stall_PC,          
    output wire       stall_IF_ID,       
    output wire       flush_ID_E         
);

    // =========================================================================
    // TRÍCH XUẤT CÁC TÍN HIỆU ĐIỀU KHIỂN TỪ BUS 16-BIT CỦA CPU_TOP
    // =========================================================================
    
    // Bit [1] biểu thị lệnh LOAD (lw)
    wire is_load_E    = execute_signals_E[1]; 

    // Bit [2] biểu thị cho phép ghi Register File (RegWrite)
    wire reg_write_M  = memory_signals_M[2]; 
    wire reg_write_W  = writeback_signals_W[2]; 

    // =========================================================================
    // MẠCH LOGIC ĐI TẮT DỮ LIỆU (FORWARDING)
    // =========================================================================
    always @(*) begin
        if (reg_write_M && (rd_addr_M != 5'b0) && (rd_addr_M == rs1_addr_E)) begin
            forward_rs1 = 2'b10; // Forward từ tầng MEM
        end
        else if (reg_write_W && (rd_addr_W != 5'b0) && (rd_addr_W == rs1_addr_E)) begin
            forward_rs1 = 2'b01; // Forward từ tầng WB
        end
        else begin
            forward_rs1 = 2'b00; // Không forward
        end
    end

    always @(*) begin
        if (reg_write_M && (rd_addr_M != 5'b0) && (rd_addr_M == rs2_addr_E)) begin
            forward_rs2 = 2'b10; // Forward từ tầng MEM
        end
        else if (reg_write_W && (rd_addr_W != 5'b0) && (rd_addr_W == rs2_addr_E)) begin
            forward_rs2 = 2'b01; // Forward từ tầng WB
        end
        else begin
            forward_rs2 = 2'b00; // Không forward
        end
    end

    // Early forwarding cho ID Stage (phục vụ bộ so sánh rẽ nhánh)
    always @(*) begin
        forward_decode[0] = (reg_write_W && (rd_addr_W != 5'b0) && (rd_addr_W == rs1_addr_D)) ? 1'b1 : 1'b0;
        forward_decode[1] = (reg_write_W && (rd_addr_W != 5'b0) && (rd_addr_W == rs2_addr_D)) ? 1'b1 : 1'b0;
    end

    // =========================================================================
    // LOGIC STALL & FLUSH (Load-Use Hazard)
    // =========================================================================
    wire load_use_hazard;
    assign load_use_hazard = is_load_E && (rd_addr_E != 5'b0) && 
                             ((rd_addr_E == rs1_addr_D) || (rd_addr_E == rs2_addr_D));

    assign stall_PC    = load_use_hazard;
    assign stall_IF_ID = load_use_hazard;
    assign flush_ID_E  = load_use_hazard || branch_taken;

endmodule