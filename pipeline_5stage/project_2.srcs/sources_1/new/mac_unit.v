`timescale 1ns / 1ps

module mac_unit (
    input wire clk,
    input wire reset,         // Đồng bộ với hệ thống
    input wire mac_clr,       // Tín hiệu xóa Accumulator (ACC = 0)
    input wire mac_add,       // Tín hiệu kích hoạt nhân cộng dồn (ACC = ACC + A * B)
    input wire [31:0] operand_a,
    input wire [31:0] operand_b,
    output wire [31:0] mac_data_out // Trả về 32-bit thấp của ACC cho CPU
);
    reg [63:0] accumulator;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            accumulator <= 64'd0;
        end else begin
            if (mac_clr) begin
                accumulator <= 64'd0;
            end else if (mac_add) begin
                // Phép toán tổ hợp nhân chập dấu (Signed MAC)
                accumulator <= accumulator + ($signed(operand_a) * $signed(operand_b));
            end
        end
    end

    // Đẩy 32 bit thấp của thanh ghi tích lũy ra để chuẩn bị ghi về Register File
    assign mac_data_out = accumulator[31:0];

endmodule