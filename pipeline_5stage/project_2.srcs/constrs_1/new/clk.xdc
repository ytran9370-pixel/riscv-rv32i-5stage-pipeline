################################################################################
# TIMING CONSTRAINTS FOR 5-STAGE PIPELINE RISC-V CORE (CPU_Top)
################################################################################

# 1. Tạo ràng buộc Xung nhịp (Clock Constraint)
# Thiết lập chu kỳ 20.000 ns (tương đương 50 MHz), Duty Cycle 50% (10 ns HIGH, 10 ns LOW)
create_clock -period 20.000 -name clk -waveform {0.000 10.000} [get_ports clk]

# 2. Thiết lập thuộc tính Jitter / Uncertainty cho clock (Tùy chọn giúp tổng hợp sát thực tế)
set_clock_uncertainty 0.200 [get_clocks clk]

# 3. Tối ưu hóa đường truyền Reset (Asynchronous / Synchronous Reset)
# Giúp Vivado không phân tích đường timing khắt khe cho cổng Reset đầu vào
set_false_path -from [get_ports reset]