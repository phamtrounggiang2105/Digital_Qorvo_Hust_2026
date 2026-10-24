# Danh mục Rà soát Thiết kế & Kiểm chứng Ký duyệt (Debug & Sign-Off Checklist)

## 1. Danh mục Kiểm tra Thiết kế RTL (RTL Design Sign-off)
- [x] **Top-Down Specification First:** Đặc tả kiến trúc hoàn chỉnh trước khi cài đặt mã nguồn (`docs/SPECIFICATION.md`).
- [x] **Single Synchronous Clock Domain:** 100% Flip-Flop trong hệ thống được kích hoạt đồng nhất bởi `posedge clk` (1 MHz), không có ripple clock hay CDC.
- [x] **Reset Synchronization & Recovery:** Tín hiệu reset ngoại vi đi qua bộ đồng bộ hóa 2 tầng [`reset_sync.sv`](file:///home/ngobinh/HMS_Timer/rtl/reset_sync.sv) chống vi phạm thời gian recovery/removal.
- [x] **Strict Parameter Naming Convention:** 100% tham số `parameter` bắt đầu bằng tiền tố `P_` và hằng số nội bộ `localparam` bắt đầu bằng `PL_`.
- [x] **Standard Pulse Nomenclature:** 100% các xung cho phép / sự kiện đơn chu kỳ sử dụng danh pháp `pulse` (`pulse_1khz`, `sec_pulse`, `btn_pulse`, `load_pulse`), triệt tiêu hoàn toàn từ khóa `tick`.
- [x] **Zero Latch Inference:** Tất cả các khối logic tổ hợp đều gán đầy đủ giá trị mặc định, không để hở nhánh gán suy diễn chốt (latch-free).
- [x] **Zero Combinational Feedback Loops:** Tất cả khối tuần tự sử dụng phép gán không chặn (`<=`), khối tổ hợp sử dụng phép gán chặn (`=`).
- [x] **Pure Structural Top Level:** Module đỉnh [`hms_timer.sv`](file:///home/ngobinh/HMS_Timer/rtl/hms_timer.sv) thuần kết nối cấu trúc 100%, không chứa câu lệnh `assign` logic hay khối `always`.
- [x] **Zero AI Watermarks:** Không chứa bất kỳ định danh AI nào trong phần đầu hoặc chú thích tệp mã nguồn.

---

## 2. Danh mục Kiểm tra Môi trường Testbench & Coverage (Verification Sign-off)
- [x] **Requirement Traceability (RTM):** 100% các yêu cầu từ đặc tả được ánh xạ vào ma trận RTM và có bài test kiểm chứng tương ứng.
- [x] **Modular Verification Testsuite:** Tổ chức thành 6 phân hệ kiểm thử độc lập (`tb/tests/`) với 133 hạng mục xác minh cụ thể.
- [x] **SystemVerilog Concurrent Assertions (SVA):** Tích hợp 24 luật assertions giám sát độ rộng xung, tính toàn vẹn trạng thái và giới hạn dải số (100.00% PASS).
- [x] **Cycle-Accurate Golden Scoreboard:** Scoreboard đối soát tự động từng chu kỳ clock, không false-pass.
- [x] **Functional Coverage Target:** Đạt tuyệt đối **100.00% (74/74 bins)** trên toàn bộ 4 Covergroups (`cg_fsm_modes`, `cg_time_values`, `cg_stimulus_cross`, `cg_commit_collision`).
- [x] **Condition Coverage Target:** Đạt tuyệt đối **100.00% (37/37 bins)** sau khi bổ sung kịch bản xung đột phím UP + DOWN trong tất cả các chế độ chỉnh sửa.
- [x] **FSM States & Transitions:** Đạt tuyệt đối **100.00%** (4/4 states và 6/6 transitions).
- [x] **Statement & Branch Coverage:** Đạt **99.21%** Statement (126/127) và **96.37%** Branch (133/138).
- [x] **Overall QuestaSim Coverage:** Đạt **96.03%** tổng hợp mã nguồn và chức năng.
- [x] **Full Regression PASS:** Toàn bộ 133 bài test và 367 assertions/checks đạt trạng thái **100% PASSED**.
