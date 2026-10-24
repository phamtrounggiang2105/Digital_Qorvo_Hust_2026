# RTL Module Hierarchy & Interconnect Matrix (Universal Synchronous Architecture)

## 1. Top-Level Module: [`hms_timer`](file:///home/ngobinh/HMS_Timer/rtl/hms_timer.sv)

### 1.1 Parameters

**Bảng 1.1: Bảng tham số thiết kế cấu hình Top Module hms_timer**

| Parameter | Default Value | Description |
| :--- | :---: | :--- |
| `P_CLK_FREQ_HZ` | `1_000_000` | Tần số xung nhịp hệ thống Master Clock (1 MHz mặc định, hỗ trợ mở rộng) |
| `P_PULSE_1KHZ_FREQ_HZ` | `1_000` | Tần số xung lấy mẫu cho khối khử rung phím (1 kHz) |
| `P_DEBOUNCE_PULSES` | `20` | Ngưỡng đếm khử rung phím (20 xung mẫu = 20 ms) |
| `P_TIMEOUT_SEC` | `5` | Ngưỡng đếm thời gian tự động thoát chế độ chỉnh sửa (5 giây) |
| `P_SEC_WIDTH` | `6` | Độ rộng bit của bộ đếm và bộ đệm Giây (0 .. 59) |
| `P_MIN_WIDTH` | `6` | Độ rộng bit của bộ đếm và bộ đệm Phút (0 .. 59) |
| `P_HOUR_WIDTH` | `5` | Độ rộng bit của bộ đếm và bộ đệm Giờ (0 .. 23) |

*Ghi chú: 100% tham số module tuân thủ tiền tố P_ theo chuẩn đặc tả kiến trúc RTL.*

### 1.2 Top-Level I/O Ports

**Bảng 1.2: Bảng chân tín hiệu ngoại vi Top Module hms_timer**

| Port Name | Direction | Width | Type | Description |
| :--- | :---: | :---: | :---: | :--- |
| `clk` | Input | 1 | Clock | Xung nhịp đồng bộ chủ 1 MHz toàn cục |
| `rstn` | Input | 1 | Reset | Reset bất đồng bộ mức thấp (Active-Low) |
| `sel_in` | Input | 1 | Async Control | Nút bấm chọn chế độ ngoại vi (khử rung 20ms) |
| `up_in` | Input | 1 | Async Control | Nút bấm tăng giá trị ngoại vi (khử rung 20ms) |
| `down_in` | Input | 1 | Async Control | Nút bấm giảm giá trị ngoại vi (khử rung 20ms) |
| `h_out` | Output | 5 | Data Out | Ngõ ra hiển thị Giờ (0 .. 23) |
| `m_out` | Output | 6 | Data Out | Ngõ ra hiển thị Phút (0 .. 59) |
| `s_out` | Output | 6 | Data Out | Ngõ ra hiển thị Giây (0 .. 59) |

*Ghi chú: Toàn bộ ngõ vào nút bấm bất đồng bộ đều được đồng bộ hóa và lọc rung trước khi đưa vào lõi xử lý FSM.*

---

## 2. Sub-module Hierarchy Tree

```text
hms_timer (Top - Universal Synchronous Single-Clock Domain Architecture)
├── u_reset_sync           [reset_sync.sv - 2-Stage Flip-Flop Synchronous Reset Synchronizer]
│   ├── r_sync_stage1       (Stage 1 Synchronizer FF, async_reg = "true")
│   └── r_sync_stage2       (Stage 2 Synchronizer FF, async_reg = "true")
├── u_clk_prescaler        [clk_prescaler.sv - 2-Stage Cascaded Frequency Divider]
│   ├── r_cnt_1khz[9:0]     (Stage 1: Modulo-1000, 1 MHz -> 1 kHz pulse_1khz)
│   └── r_cnt_1hz[9:0]      (Stage 2: Modulo-1000 clocked on 1 MHz, enabled by pulse_1khz -> 1 Hz sec_pulse)
├── u_button_controller   [button_controller.sv - Multi-Channel Button Controller & Pulse Alignment]
│   ├── u_debouncer_sel     (button_debouncer for sel_in)
│   ├── u_debouncer_up      (button_debouncer for up_in)
│   └── u_debouncer_down    (button_debouncer for down_in)
├── u_mode_controller      [mode_controller.sv - FSM Mode Controller & Inactivity Timer]
│   ├── state_reg[1:0]      (4-State FSM: RUN, ADJ_SEC, ADJ_MIN, ADJ_HOUR)
│   ├── timeout_cnt[2:0]    (5-Second Inactivity Timer -> auto-exit without load_en)
│   ├── r_adj_sec[5:0]      (Edit Buffer: Second)
│   ├── r_adj_min[5:0]      (Edit Buffer: Minute)
│   ├── r_adj_hour[4:0]     (Edit Buffer: Hour)
│   └── r_load_en           (1-cycle Commit Pulse to load counters)
├── u_second_counter       [second_counter.sv - Continuous Background Counter with Native Clock Enable]
│   └── r_sec[5:0]          (Modulo-60 Counter with Synchronous Parallel Load)
├── u_minute_counter       [minute_counter.sv - Continuous Background Counter with Native Clock Enable]
│   └── r_min[5:0]          (Modulo-60 Counter with Synchronous Parallel Load)
├── u_hour_counter         [hour_counter.sv - Continuous Background Counter with Native Clock Enable]
│   └── r_hour[4:0]         (Modulo-24 Counter with Synchronous Parallel Load)
└── u_output_switch        [output_switch.sv - Combinational Display Multiplexer]
    ├── Second MUX (s_out = (RUN && !load_en) ? s_cnt : adj_sec)
    ├── Minute MUX (m_out = (RUN && !load_en) ? m_cnt : adj_min)
    └── Hour MUX   (h_out = (RUN && !load_en) ? h_cnt : adj_hour)
```

---

## 3. Internal Interconnect Matrix

**Bảng 1.3: Bảng kết nối tín hiệu nội bộ giữa các Sub-module trong hms_timer**

| Internal Signal | Width | Driver Module | Receiver Module(s) | Function |
| :--- | :---: | :--- | :--- | :--- |
| `rstn_sync` | 1 | [`u_reset_sync`](file:///home/ngobinh/HMS_Timer/rtl/reset_sync.sv) | Toàn bộ các sub-module tuần tự | Reset đồng bộ hóa tích cực mức thấp, triệt tiêu vi phạm recovery/removal |
| `pulse_1khz` | 1 | [`u_clk_prescaler`](file:///home/ngobinh/HMS_Timer/rtl/clk_prescaler.sv) | [`u_button_controller`](file:///home/ngobinh/HMS_Timer/rtl/button_controller.sv) | Xung lấy mẫu 1 chu kỳ clock (1 kHz) cho 3 bộ lọc rung phím |
| `sec_pulse` | 1 | [`u_clk_prescaler`](file:///home/ngobinh/HMS_Timer/rtl/clk_prescaler.sv) | [`u_second_counter`](file:///home/ngobinh/HMS_Timer/rtl/second_counter.sv), [`u_mode_controller`](file:///home/ngobinh/HMS_Timer/rtl/mode_controller.sv) | Xung thời gian thực 1 chu kỳ clock (1 Hz) cấp cho bộ đếm giây và timer timeout |
| `sel_pulse` | 1 | [`u_button_controller`](file:///home/ngobinh/HMS_Timer/rtl/button_controller.sv) | [`u_mode_controller`](file:///home/ngobinh/HMS_Timer/rtl/mode_controller.sv) | Xung đơn chu kỳ tích cực khi nút SEL được nhấn giữ đủ 20ms |
| `up_pulse` | 1 | [`u_button_controller`](file:///home/ngobinh/HMS_Timer/rtl/button_controller.sv) | [`u_mode_controller`](file:///home/ngobinh/HMS_Timer/rtl/mode_controller.sv) | Xung đơn chu kỳ tích cực khi nút UP được nhấn giữ đủ 20ms |
| `down_pulse` | 1 | [`u_button_controller`](file:///home/ngobinh/HMS_Timer/rtl/button_controller.sv) | [`u_mode_controller`](file:///home/ngobinh/HMS_Timer/rtl/mode_controller.sv) | Xung đơn chu kỳ tích cực khi nút DOWN được nhấn giữ đủ 20ms |
| `adj_mode[1:0]` | 2 | [`u_mode_controller`](file:///home/ngobinh/HMS_Timer/rtl/mode_controller.sv) | [`u_output_switch`](file:///home/ngobinh/HMS_Timer/rtl/output_switch.sv) | Trạng thái chế độ hiện tại (00:RUN, 01:SEC, 10:MIN, 11:HOUR) |
| `load_en` | 1 | [`u_mode_controller`](file:///home/ngobinh/HMS_Timer/rtl/mode_controller.sv) | [`u_second_counter`](file:///home/ngobinh/HMS_Timer/rtl/second_counter.sv), [`u_minute_counter`](file:///home/ngobinh/HMS_Timer/rtl/minute_counter.sv), [`u_hour_counter`](file:///home/ngobinh/HMS_Timer/rtl/hour_counter.sv), [`u_output_switch`](file:///home/ngobinh/HMS_Timer/rtl/output_switch.sv) | Xung 1 chu kỳ nạp song song giá trị bộ đệm vào bộ đếm nền khi xác nhận |
| `adj_sec[5:0]` | 6 | [`u_mode_controller`](file:///home/ngobinh/HMS_Timer/rtl/mode_controller.sv) | [`u_output_switch`](file:///home/ngobinh/HMS_Timer/rtl/output_switch.sv), [`u_second_counter`](file:///home/ngobinh/HMS_Timer/rtl/second_counter.sv) | Giá trị giây trong bộ đệm chỉnh giờ |
| `adj_min[5:0]` | 6 | [`u_mode_controller`](file:///home/ngobinh/HMS_Timer/rtl/mode_controller.sv) | [`u_output_switch`](file:///home/ngobinh/HMS_Timer/rtl/output_switch.sv), [`u_minute_counter`](file:///home/ngobinh/HMS_Timer/rtl/minute_counter.sv) | Giá trị phút trong bộ đệm chỉnh giờ |
| `adj_hour[4:0]` | 5 | [`u_mode_controller`](file:///home/ngobinh/HMS_Timer/rtl/mode_controller.sv) | [`u_output_switch`](file:///home/ngobinh/HMS_Timer/rtl/output_switch.sv), [`u_hour_counter`](file:///home/ngobinh/HMS_Timer/rtl/hour_counter.sv) | Giá trị giờ trong bộ đệm chỉnh giờ |
| `s_cnt[5:0]` | 6 | [`u_second_counter`](file:///home/ngobinh/HMS_Timer/rtl/second_counter.sv) | [`u_output_switch`](file:///home/ngobinh/HMS_Timer/rtl/output_switch.sv), [`u_mode_controller`](file:///home/ngobinh/HMS_Timer/rtl/mode_controller.sv) | Giá trị giây thời gian thực từ bộ đếm nền |
| `m_cnt[5:0]` | 6 | [`u_minute_counter`](file:///home/ngobinh/HMS_Timer/rtl/minute_counter.sv) | [`u_output_switch`](file:///home/ngobinh/HMS_Timer/rtl/output_switch.sv), [`u_mode_controller`](file:///home/ngobinh/HMS_Timer/rtl/mode_controller.sv) | Giá trị phút thời gian thực từ bộ đếm nền |
| `h_cnt[4:0]` | 5 | [`u_hour_counter`](file:///home/ngobinh/HMS_Timer/rtl/hour_counter.sv) | [`u_output_switch`](file:///home/ngobinh/HMS_Timer/rtl/output_switch.sv), [`u_mode_controller`](file:///home/ngobinh/HMS_Timer/rtl/mode_controller.sv) | Giá trị giờ thời gian thực từ bộ đếm nền |
| `sec_rollover` | 1 | [`u_second_counter`](file:///home/ngobinh/HMS_Timer/rtl/second_counter.sv) | [`u_minute_counter`](file:///home/ngobinh/HMS_Timer/rtl/minute_counter.sv) | Xung cờ tràn giây 1 chu kỳ khi `s_cnt == 59 & sec_pulse & ~load_en` |
| `min_rollover` | 1 | [`u_minute_counter`](file:///home/ngobinh/HMS_Timer/rtl/minute_counter.sv) | [`u_hour_counter`](file:///home/ngobinh/HMS_Timer/rtl/hour_counter.sv) | Xung cờ tràn phút 1 chu kỳ khi `m_cnt == 59 & sec_rollover & ~load_en` |

*Ghi chú: Toàn bộ tín hiệu xung điều khiển nội bộ tuân thủ nghiêm ngặt danh pháp pulse, loại bỏ 100% từ khóa tick.*
