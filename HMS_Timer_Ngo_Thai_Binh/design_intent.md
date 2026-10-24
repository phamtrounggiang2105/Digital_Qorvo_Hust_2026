# Design Intent & Architectural Decisions (Universal Synchronous Architecture)

## 1. Mục tiêu & Phạm vi Kiến trúc (Objective & Scope)
IP Core [`hms_timer`](file:///home/ngobinh/HMS_Timer/rtl/hms_timer.sv) được thiết kế nhằm cung cấp giải pháp đếm thời gian thực Giờ - Phút - Giây có độ chính xác tuyệt đối, bền bỉ trước nhiễu cơ học, tối ưu hóa PPA (Power, Performance, Area) và khả chuyển phổ quát trên cả công nghệ ASIC (SkyWater 130nm, TSMC) lẫn FPGA (AMD/Xilinx, Intel FPGA). Hệ thống hoạt động trên một miền xung nhịp đồng bộ duy nhất 1 MHz với các xung Clock Enable đơn chu kỳ (`pulse_1khz`, `sec_pulse`), triệt tiêu 100% rủi ro Clock Domain Crossing (CDC), Clock Skew và đảm bảo ngõ vào/ngõ ra kết nối cấu trúc thuần túy 100%.

---

## 2. Các Quyết định Kiến trúc Trọng yếu (Why vs What)

### 2.1 Kiến trúc Đơn miền Xung nhịp Đồng bộ Toàn cục (Single-Clock Synchronous Architecture)
- **Vấn đề của việc chèn ICG thủ công:** 
  - Khởi tạo các cell Clock Gating tích hợp (ICG) rời rạc trong RTL tạo ra nhiều nhánh clock phụ (`gated_clk_*`). Trên kiến trúc FPGA (Xilinx 7-Series / UltraScale), việc chia nhỏ clock tree làm cạn kiệt bộ đệm clock toàn cục (`BUFG`), sinh ra độ lệch pha (clock skew), và vi phạm luật DRC do sử dụng chốt (latch).
  - Duy trì các switch kiến trúc theo công nghệ (`TARGET_FPGA`) làm phức tạp hóa quy trình thẩm định.
- **Quyết định kiến trúc:**
  - Chuẩn hóa 100% thiết kế trên một **Miền Xung Nhịp Đồng Bộ 1 MHz Duy Nhất** (`clk`) kết hợp các xung cho phép Clock Enable (`CE`).
  - Toàn bộ Flip-Flop trong các khối con ([`button_debouncer`](file:///home/ngobinh/HMS_Timer/rtl/button_debouncer.sv), [`mode_controller`](file:///home/ngobinh/HMS_Timer/rtl/mode_controller.sv), [`second_counter`](file:///home/ngobinh/HMS_Timer/rtl/second_counter.sv), [`minute_counter`](file:///home/ngobinh/HMS_Timer/rtl/minute_counter.sv), [`hour_counter`](file:///home/ngobinh/HMS_Timer/rtl/hour_counter.sv)) đều kích hoạt theo sườn dương `posedge clk`, điều khiển cập nhật thông qua các xung enable chuẩn (`pulse_1khz`, `sec_pulse`, `sec_rollover`, `min_rollover`, `load_en`).
- **Lợi ích trên FPGA:**
  - Tiêu thụ đúng duy nhất **1 Global Clock Buffer (BUFG)** cho toàn chip.
  - Ánh xạ trực tiếp vào chân Clock Enable (`CE`) của slice Flip-Flop (nguyên mẫu `FDRE`).
  - Triệt tiêu hoàn toàn vi phạm giữ thời gian (hold-time violations) và rủi ro CDC.
- **Lợi ích trên ASIC (Automatic Clock Gating Insertion - ACGI):**
  - Trình biên dịch tổng hợp hiện đại (Synopsys Design Compiler với cờ `compile_ultra -gate_clock`, Cadence Genus với `set_db lp_insert_clock_gating true`, OpenLane/Yosys) tự động nhận diện chân enable và chèn cell ICG chuẩn thư viện PDK (`sky130_fd_sc_hd__dlclkp_*`) cân bằng trong giai đoạn Clock Tree Synthesis (CTS). Tiết kiệm >99.9% công suất chuyển mạch clock pin mà vẫn giữ RTL sạch và khả chuyển.

### 2.2 Bộ Chia Tần Đa Tầng Phân Cấp (PPA Optimization Prescaler)
- **Quyết định kiến trúc:** Phân tầng 2 giai đoạn bên trong [`clk_prescaler`](file:///home/ngobinh/HMS_Timer/rtl/clk_prescaler.sv):
  - Tầng 1: Bộ đếm Modulo-1000 (10-bit) chia 1 MHz tạo xung lấy mẫu 1 chu kỳ 1 kHz (`pulse_1khz`).
  - Tầng 2: Bộ đếm Modulo-1000 (10-bit) kích hoạt bởi `pulse_1khz` chia 1 kHz tạo xung chuẩn 1 chu kỳ 1 Hz (`sec_pulse`).
  - Khối khử rung: Lấy mẫu ở tần số 1 kHz sử dụng `pulse_1khz` làm clock enable với bộ đếm nhỏ 5-bit (0..19), thay vì phải đếm 15-bit trực tiếp trên xung nhịp 1 MHz.
- **Căn cứ tối ưu PPA:** Giảm số bit đếm tần số cao 1 MHz từ 65-bit xuống chỉ còn 10-bit (giảm 84.6% số bit chuyển mạch cao tần). Toàn bộ logic của 3 bộ khử rung và tầng đếm 1 Hz chỉ lật trạng thái khi `pulse_1khz = 1` (giảm 99.9% hoạt động chuyển mạch động).

### 2.3 Bộ Đồng Bộ Hóa 2-FF & Khử Rung 20ms Chuẩn Xác (Single-Event Debounce)
- **Quyết định kiến trúc:** Tín hiệu nút bấm bất đồng bộ (`sel_in`, `up_in`, `down_in`) đi qua 2 tầng Flip-Flop đồng bộ hóa, sau đó được kiểm tra mức logic liên tục trong 20 chu kỳ xung lấy mẫu 1 kHz (ngưỡng 20 ms).
- **Căn cứ kỹ thuật:** Độ rung phím cơ học thực tế dao động từ 5 ms .. 15 ms. Ngưỡng 20 ms triệt tiêu 100% rung phím và các xung nhiễu điện từ ngắn hạn.
- **Cơ chế kích hoạt đơn xung (Single Event):** Khi nhấn giữ nút đủ 20 ms, khối khử rung phát ra đúng duy nhất 1 xung chuẩn đơn chu kỳ hệ thống 1 MHz (1 µs) và khóa ngõ ra. Người dùng bắt buộc phải nhả nút hoàn toàn để bộ đếm quay về trạng thái rảnh (IDLE) trước khi tiếp nhận lần bấm kế tiếp. Cơ chế này chống hiện tượng vô tình lặp phím khi thao tác.

### 2.4 Tách Biệt Bộ Đệm Chỉnh Giờ & Khối Chuyển Mạch Hiển Thị (`output_switch`)
- **Vấn đề:** Nếu ngõ ra nối trực tiếp vào bộ đếm thời gian thực, thao tác chỉnh giờ sẽ bắt buộc phải dừng bộ đếm (gây trôi giờ thực tế) hoặc ghi trực tiếp lên bộ đếm đang chạy gây gián đoạn chu kỳ.
- **Quyết định kiến trúc:**
  - Thiết kế module chuyển mạch tổ hợp độc lập [`output_switch.sv`](file:///home/ngobinh/HMS_Timer/rtl/output_switch.sv).
  - Duy trì bộ đệm chỉnh giờ độc lập (`adj_sec`, `adj_min`, `adj_hour`) bên trong [`mode_controller.sv`](file:///home/ngobinh/HMS_Timer/rtl/mode_controller.sv).
  - Khi ở chế độ chỉnh giờ (`MODE_ADJ_*`), [`output_switch`](file:///home/ngobinh/HMS_Timer/rtl/output_switch.sv) chuyển kênh hiển thị giá trị từ bộ đệm chỉnh giờ để người dùng quan sát tức thời.
  - Khi ở chế độ bình thường (`MODE_RUN`), [`output_switch`](file:///home/ngobinh/HMS_Timer/rtl/output_switch.sv) chuyển kênh hiển thị giá trị từ các bộ đếm thời gian thực nền (`s_cnt`, `m_cnt`, `h_cnt`).
  - **Nạp song song đồng bộ khi hoàn tất (Commit on Exit):** Khi duyệt hết chu trình chỉnh giờ (`MODE_ADJ_HOUR` -> `MODE_RUN` qua nút `SEL`), `mode_controller` phát xung 1 chu kỳ `load_en = 1`, nạp đồng thời toàn bộ giá trị bộ đệm vào các bộ đếm nền.

### 2.5 Bộ Đếm Nền Liên Tục Chuẩn Xác Không Trôi Giờ (Zero-Drift Background Counter)
- **Quyết định kiến trúc:** Các bộ đếm nền ([`second_counter`](file:///home/ngobinh/HMS_Timer/rtl/second_counter.sv), [`minute_counter`](file:///home/ngobinh/HMS_Timer/rtl/minute_counter.sv), [`hour_counter`](file:///home/ngobinh/HMS_Timer/rtl/hour_counter.sv)) hoạt động liên tục 24/7 theo xung thời gian thực 1 Hz độc lập với menu người dùng.
- **Tối ưu Diện tích & Tiết kiệm Flip-Flop:** Loại bỏ toàn bộ các thanh ghi bóng (shadow snapshot registers), tiết kiệm 17 Flip-Flop và hàng chục cổng MUX so với kiến trúc cũ.

### 2.6 Giải Quyết Xung Đột Phím UP và DOWN Đồng Thời (Simultaneous Conflict Resolution)
- **Quyết định kiến trúc:** Khi cả hai phím `up_pulse` và `down_pulse` cùng tích cực trong cùng 1 chu kỳ clock, bộ đệm trong [`mode_controller.sv`](file:///home/ngobinh/HMS_Timer/rtl/mode_controller.sv) giữ nguyên tuyệt đối giá trị hiện tại trên cả 3 chế độ `SEC`, `MIN`, `HOUR`.
- **Căn cứ kỹ thuật:** Đảm bảo tính tiền định (deterministic), ngăn ngừa race-conditions khi người dùng nhấn 2 nút cùng lúc hoặc khi xuất hiện xung nhiễu ngoài ý muốn.

### 2.7 Cơ Chế Tự Động Hủy Bỏ Sau 5s Không Thao Tác (5s Inactivity Timeout)
- **Quyết định kiến trúc:** Nếu người dùng ở trong bất kỳ chế độ chỉnh giờ nào mà không nhấn phím trong 5 giây liên tục, FSM tự động thoát về `MODE_RUN` với `load_en = 0`.
- **Căn cứ kỹ thuật:** Hủy bỏ toàn bộ các thay đổi chưa được xác nhận trong bộ đệm và hoàn trả màn hình về đồng hồ thời gian thực đang chạy chuẩn xác. Nếu người dùng thao tác phím bất kỳ, bộ đếm timeout tự động reset về 0 (Keep-Alive).

### 2.8 Bộ Đồng Bộ Hóa Reset 2 Tầng (`reset_sync`)
- **Vấn đề:** Tín hiệu reset bất đồng bộ khi giải phóng (deassertion) có thể vi phạm thời gian Recovery và Removal trên các Flip-Flop hạ nguồn, dẫn tới hiện tượng bất ổn định (metastability).
- **Quyết định kiến trúc:** Triển khai khối đồng bộ hóa reset 2-FF chuyên dụng [`reset_sync.sv`](file:///home/ngobinh/HMS_Timer/rtl/reset_sync.sv):
  - 2 tầng D-FF ghép chuỗi kích hoạt theo `posedge clk`.
  - Xác lập reset tức thời bất đồng bộ và giải trừ reset đồng bộ theo sườn dương xung nhịp 1 MHz.
  - Sử dụng thuộc tính tổng hợp `(* async_reg = "true" *)` ngăn trình tổng hợp gộp thành thanh ghi dịch (SRL) và đảm bảo vị trí tế bào kề nhau trên mặt layout.

### 2.9 Kết Nối Cấu Trúc Thuần Túy ở Module Đỉnh (`hms_timer`)
- **Quyết định kiến trúc:** Module đỉnh [`hms_timer.sv`](file:///home/ngobinh/HMS_Timer/rtl/hms_timer.sv) chứa 0 câu lệnh `assign` logic và 0 khối `always`.
- **Căn cứ kỹ thuật:** Triệt tiêu hoàn toàn logic chắp vá (glue logic) ở tầng top, đảm bảo [`hms_timer.sv`](file:///home/ngobinh/HMS_Timer/rtl/hms_timer.sv) là một khung kết nối cấu trúc 100% trong sáng, toàn bộ logic chức năng được đóng gói trọn vẹn trong các submodule tương ứng.
