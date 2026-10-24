# Sổ tay Khắc phục Sự cố & Gỡ lỗi Thực chiến (Common Failures & Debug Playbook)

## 1. Bẫy Tỷ lệ Xung nhịp Mô phỏng Nhanh (Fast-Simulation Clock Ratio Trap)
- **Hiện tượng:** Bộ đếm giây tự động tăng thêm 1 đơn vị ngoài ý muốn trong quá trình nhấn nút chuyển chế độ.
- **Nguyên nhân gốc rễ:** Nếu cấu hình tần số xung nhịp mô phỏng `PL_SIM_CLK_FREQ_HZ` quá thấp (ví dụ 5 cycles/giây), một thao tác bấm nút thông thường (kéo dài 20 cycles) sẽ chiếm trọn một chu kỳ phát xung `sec_pulse` trong khi DUT vẫn chưa hoàn tất chuyển khỏi `MODE_RUN`.
- **Giải pháp xử lý:** Luôn đảm bảo `PL_SIM_CLK_FREQ_HZ >= 100` trong môi trường testbench để các thao tác nhấn nút (20 chu kỳ debounce + 25 chu kỳ an toàn) kết thúc dứt khoát trước khi xung `sec_pulse` tự nhiên tiếp theo xuất hiện.

---

## 2. Rò rỉ Cờ Tràn Giây sang Phút khi Chỉnh Sửa (Rollover Enable Leakage during Adjustment)
- **Hiện tượng:** Bộ đếm phút bị tăng thêm 1 đơn vị khi người dùng chỉnh giây quay vòng từ 59 về 00 trong chế độ `MODE_ADJ_SEC`.
- **Nguyên nhân gốc rễ:** Logic tạo cờ tràn giây không được cách ly độc lập giữa bộ đệm chỉnh giờ và bộ đếm nền thời gian thực.
- **Giải pháp xử lý:** Tách biệt hoàn toàn bộ đệm chỉnh sửa (`r_adj_sec`) trong [`mode_controller.sv`](file:///home/ngobinh/HMS_Timer/rtl/mode_controller.sv) và bộ đếm nền (`r_sec`) trong [`second_counter.sv`](file:///home/ngobinh/HMS_Timer/rtl/second_counter.sv). Cờ `sec_rollover` chỉ sinh ra từ bộ đếm thời gian thực nền theo phương trình:
  ```verilog
  assign sec_rollover = (r_sec == 6'd59) & sec_pulse & ~load_en;
  ```

---

## 3. Xung đột Đồng thời Nạp Song song & Cờ Tràn (Load vs Rollover Collision Corner)
- **Hiện tượng:** Khi người dùng nhấn nút xác nhận kết thúc chỉnh giờ (`ADJ_HOUR` -> `MODE_RUN`), nếu thời điểm này trùng khít với chu kỳ tràn 59 về 00 của bộ đếm nền, bộ đếm phút có thể bị nhảy 2 lần.
- **Nguyên nhân gốc rễ:** Xung nạp song song `load_en` và cờ tràn `sec_rollover` cùng tích cực ở một chu kỳ clock.
- **Giải pháp xử lý:** Khối [`second_counter.sv`](file:///home/ngobinh/HMS_Timer/rtl/second_counter.sv) và [`minute_counter.sv`](file:///home/ngobinh/HMS_Timer/rtl/minute_counter.sv) bổ sung term `& ~load_en` vào biểu thức tạo cờ tràn. Khi `load_en = 1`, cờ tràn bị cưỡng bức về mức 0 (loại trừ lẫn nhau), ưu tiên tuyệt đối cho giá trị mới được nạp vào.

---

## 4. Xung đột Nút Bấm Đồng thời (Simultaneous UP + DOWN Conflict)
- **Hiện tượng:** Giá trị bộ đệm thay đổi không kiểm soát khi người dùng ấn đồng thời cả 2 nút UP và DOWN trong các chế độ chỉnh sửa.
- **Nguyên nhân gốc rễ:** Sử dụng cấu trúc `if (up) ... if (down) ...` không ưu tiên hoặc thiếu phân nhánh bắt trường hợp đồng thời.
- **Giải pháp xử lý:** Trong [`mode_controller.sv`](file:///home/ngobinh/HMS_Timer/rtl/mode_controller.sv), triển khai logic giải quyết xung đột rõ ràng trên cả 3 chế độ `SEC`, `MIN`, `HOUR`:
  ```verilog
  if (up_pulse && down_pulse) begin
      // Xung đột phím: Giữ nguyên tuyệt đối giá trị hiện tại
  end else if (up_pulse) begin
      // Tăng giá trị có wrap-around
  end else begin
      // Giảm giá trị có wrap-around
  end
  ```

---

## 5. Nhiễu Rung Phím Cơ học & Kích hoạt Tự Lặp Ngoài Ý Muốn (Bounce & Auto-Repeat Glitch)
- **Hiện tượng:** Một lần nhấn phím thực tế làm đồng hồ nhảy liên tục nhiều đơn vị hoặc bị bỏ sót phím.
- **Nguyên nhân gốc rễ:** Không lọc đủ thời gian tiếp xúc cơ học (5..15 ms) hoặc mạch tự động phát xung lặp khi giữ nút.
- **Giải pháp xử lý:** Sử dụng bộ lọc rung lấy mẫu bằng xung 1 kHz (`pulse_1khz`) với bộ đếm 20 chu kỳ mẫu (20 ms). Sau khi đếm đủ 20 ms, khối [`button_debouncer.sv`](file:///home/ngobinh/HMS_Timer/rtl/button_debouncer.sv) phát ra đúng duy nhất 1 xung chuẩn đơn chu kỳ `btn_event` và chuyển sang trạng thái chờ giải phóng (WAIT_RELEASE). Người dùng bắt buộc phải nhả phím hoàn toàn trước khi có thể bấm tiếp lần sau.
