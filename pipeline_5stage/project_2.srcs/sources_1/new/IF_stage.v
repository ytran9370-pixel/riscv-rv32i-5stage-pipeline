`timescale 1ns / 1ps

module IF_stage (
    input  wire        clk,
    input  wire        reset,
    input  wire        stall,          // stall từ Hazard Unit
    input  wire [31:0] pc_plus4_E,     // Địa chỉ nhảy từ tầng EX
    input  wire        branch_taken,   // Chọn đường nhảy (1: Nhảy, 0: Tuần tự)
    
    output wire [31:0] pc_F,           // PC hiện tại của tầng IF
    output wire [31:0] inst_F          // Mã lệnh hiện tại của tầng IF
);

    reg  [31:0] pc_reg;
    wire [31:0] pc_next;
    wire [31:0] pc_plus4_F;
    wire [31:0] pc_mux_stall_out;

    // Bộ cộng PC + 4
    assign pc_plus4_F = pc_reg + 32'd4;

    // MUX dưới: Chọn giữa (PC + 4) và (PC hiện tại) dựa trên stall
    assign pc_mux_stall_out = (stall) ? pc_reg : pc_plus4_F;

    // MUX trên: Chọn đường rẽ nhánh hoặc đường tuần tự
    assign pc_next = (branch_taken) ? pc_plus4_E : pc_mux_stall_out;

    // Thanh ghi PC
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_reg <= 32'h0000_0000;
        end else begin
            pc_reg <= pc_next;
        end
    end

    // Kết nối bộ nhớ lệnh mẫu
    inst_mem_mock u_inst_mem (
        .addr(pc_reg),
        .inst(inst_F)
    );

    // Xuất dữ liệu ra rìa tầng IF
    assign pc_F = pc_reg;

endmodule

module inst_mem_mock (
    input  wire [31:0] addr,
    output wire [31:0] inst
);
    reg [31:0] imem [0:63]; 

    initial begin
        $readmemh("C:/RISCV_PRACTICE/project_2/project_2.sim/sim_1/behav/xsim/program.mem", imem);
    end
    assign inst = imem[addr[31:2]];

endmodule