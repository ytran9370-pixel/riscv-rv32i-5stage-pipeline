`timescale 1ns / 1ps
module CPU_Top_tb;
    // --- 1. Khai báo các tín hiệu kích thích cho TOP ---
    reg clk;
    reg reset;
    // --- 2. Khởi tạo module TOP cần kiểm thử (DUT) ---
    CPU_Top uut (
        .clk(clk),
        .reset(reset)
    );
    // --- 3. Định nghĩa chu kỳ tạo xung Clock (50MHz -> T = 20ns) ---
    always begin
        #10 clk = ~clk;
    end
    // --- 4. Quá trình kích thích hệ thống ---
    initial begin
        // Khởi tạo trạng thái ban đầu
        clk = 0;
        reset = 1;

        $display("==========================================================================");
        $display("   BẮT ĐẦU MÔ PHỎNG HỆ THỐNG KIẾN TRÚC PIPELINE RISC-V 5 TẦNG");
        $display("==========================================================================");

        // Kích hoạt reset trong 2 chu kỳ clock để xóa trống các vách ngăn
        #25;
        reset = 0;
        $display("[TB INFO] Hệ thống đã nhả RESET. CPU bắt đầu thực thi lệnh...");

        // Chạy mô phỏng trong 500ns (Kéo dài thêm một chút để bao quát toàn bộ chương trình)
        #500;

        $display("==========================================================================");
        $display("   MÔ PHỎNG HOÀN THÀNH CHUỖI KIỂM THỬ HAZARD & PIPELINE");
        $display("==========================================================================");
        $finish;
    end
    // --- 5. MÔI TRƯỜNG GIÁM SÁT (MONITOR): In trạng thái chi tiết theo từng chu kỳ ---
    always @(posedge clk) begin
        if (!reset) begin
            $display("--------------------------------------------------------------------------");
            $display("Time: %0d ns | CLK Posedge", $time);

            // 5.1. In thông tin tầng Fetch (IF) và Decode (ID)
            $display("[IF Stage]  PC_Fetch = 0x%h | Inst_Fetch = 0x%h", uut.pc_F, uut.inst_F);
            $display("[ID Stage]  PC_Decode = 0x%h | Inst_Decode = 0x%h | RS1_Addr = %d, RS2_Addr = %d",
                     uut.pc_D, uut.inst_D, uut.rs1_addr_D, uut.rs2_addr_D);

            // 5.2. In thông tin tầng Execute (EX) và toán hạng thực tế của ALU
            // Để hiển thị toán hạng đi vào ALU, ta truy xuất trực tiếp vào EX_stage
            $display("[EX Stage]  PC_Exec = 0x%h | Op_A = 0x%h | Op_B = 0x%h | ALU_Result_E = 0x%h | RD_Addr_E = %d",
                     uut.pc_E, uut.u_EX_stage.operand_a, uut.u_EX_stage.operand_b, uut.Result_E, uut.rd_addr_E);

            // 5.3. In thông tin tầng Memory (MEM) và Writeback (WB)
            $display("[MEM Stage] ALU_Result_M = 0x%h | RD_Addr_M = %d", uut.Result_M, uut.rd_addr_M);
            $display("[WB Stage]  Write_Data_W = 0x%h | RD_Addr_W = %d | RegWrite_W = %b",
                     uut.rd_data_W, uut.rd_addr_W_out, uut.rd_wr_W);
            // 5.4. GIÁM SÁT HAZARD & ĐIỀU PHỐI (Quan trọng nhất để debug lỗi)
            // Đã sửa đổi uut.stall thành uut.stall_PC và uut.stall_IF_ID
            $display("[HAZARD]    Stall_PC = %b | Stall_IF_ID = %b | Flush_ID_E = %b", 
                     uut.stall_PC, uut.stall_IF_ID, uut.flush_ID_E);
            $display("[FORWARD]   Fwd_RS1_E = %b | Fwd_RS2_E = %b | Fwd_Decode_D = %b", 
                     uut.forward_rs1, uut.forward_rs2, uut.forward_decode);
        end
    end
endmodule