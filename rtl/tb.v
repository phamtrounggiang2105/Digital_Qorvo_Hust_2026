// =============================================================================
// Testbench cho hms_timer (đồng hồ giờ:phút:giây, 3 nút sel/up/down)
//
// Biên dịch (Icarus Verilog):
//   iverilog -g2005 -o tb.out tb_hms_timer.v hms_timer.v reset_sync.v \
//            clk_divide.v button.v fsm.v icg.v sec.v min.v hour.v edit_time.v
//   vvp tb.out
//   gtkwave hms_timer_tb.vcd
//
// Thời gian mô phỏng ~27 s (clk 1 MHz => ~27 triệu chu kỳ), có thể mất vài chục giây.
// Dùng đúng tốc độ thật vì clk_divide cố định 1 MHz -> 1 kHz -> 1 Hz.
// =============================================================================
`timescale 1us/1ns

module tb_hms_timer;

    localparam PRESS_MS = 30;     // nhấn ngắn: > 20 ms (ngưỡng debounce up/down/sel khi edit)
    localparam LONG_MS  = 3100;   // nhấn dài: > 3000 ms (ngưỡng sel ở NORMAL)

    reg        clk, rst_n, sel_in, up_in, down_in;
    wire [5:0] s_out, m_out;
    wire [4:0] h_out;

    hms_timer dut (
        .clk(clk), .rst_n(rst_n),
        .sel_in(sel_in), .up_in(up_in), .down_in(down_in),
        .s_out(s_out), .m_out(m_out), .h_out(h_out)
    );

    // clock 1 MHz (timescale 1us -> nửa chu kỳ 0.5 us)
    initial clk = 1'b0;
    always #0.5 clk = ~clk;

    integer errors, checks;
    integer i, snap;
    reg     chk_en;

    // -------------------------------------------------------------------------
    // Mô hình tham chiếu: đếm theo pulse_1hz, nạp theo fsm_load.
    // Cập nhật cùng cạnh clk với gclk của DUT nên so sánh được ở negedge.
    // -------------------------------------------------------------------------
    reg [5:0] m_s, m_m;
    reg [4:0] m_h;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_s <= 6'd0; m_m <= 6'd0; m_h <= 5'd0;
        end else if (dut.fsm_load) begin
            m_s <= s_out; m_m <= m_out; m_h <= h_out;
        end else if (dut.pulse_1hz) begin
            if (m_s == 6'd59) begin
                m_s <= 6'd0;
                if (m_m == 6'd59) begin
                    m_m <= 6'd0;
                    m_h <= (m_h == 5'd23) ? 5'd0 : m_h + 1'b1;
                end else
                    m_m <= m_m + 1'b1;
            end else
                m_s <= m_s + 1'b1;
        end
    end

    // Checker liên tục: ở chế độ NORMAL, ngõ ra phải bằng mô hình
    always @(negedge clk) begin
        if (chk_en && rst_n && dut.rst_n_s && dut.fsm_normal) begin
            if ({h_out, m_out, s_out} !== {m_h, m_m, m_s}) begin
                errors = errors + 1;
                $display("[%0t] FAIL (model): DUT=%02d:%02d:%02d  MODEL=%02d:%02d:%02d",
                         $time, h_out, m_out, s_out, m_h, m_m, m_s);
            end
        end
    end

    // -------------------------------------------------------------------------
    // Tasks
    // -------------------------------------------------------------------------
    task check;
        input        cond;
        input [8*60-1:0] msg;
        begin
            checks = checks + 1;
            if (cond !== 1'b1) begin
                errors = errors + 1;
                $display("[%0t] FAIL: %0s   (time=%02d:%02d:%02d)", $time, msg, h_out, m_out, s_out);
            end else
                $display("[%0t] PASS: %0s", $time, msg);
        end
    endtask

    // Chờ xung 1 Hz và 2 cạnh clk sau đó (gclk cập nhật ở cạnh k+1)
    task wait_tick;
        begin
            @(posedge dut.pulse_1hz);
            repeat (2) @(posedge clk);
            #0.1;
        end
    endtask

    // which: 0 = sel, 1 = up, 2 = down ; ms = thời gian giữ nút
    task press;
        input integer which;
        input integer ms;
        begin
            @(negedge clk);
            case (which)
                0: sel_in  = 1'b1;
                1: up_in   = 1'b1;
                default: down_in = 1'b1;
            endcase
            repeat (ms * 1000) @(posedge clk);
            @(negedge clk);
            sel_in = 1'b0; up_in = 1'b0; down_in = 1'b0;
            repeat (2000) @(posedge clk);       // nghỉ 2 ms
            #0.1;
        end
    endtask

    // Chỉnh 1 trường (0=giây, 1=phút, 2=giờ) tới giá trị target bằng up/down (đi đường ngắn nhất)
    task adjust;
        input integer field;
        input integer target;
        integer cur, modv, upn, k;
        begin
            case (field)
                0: begin cur = s_out; modv = 60; end
                1: begin cur = m_out; modv = 60; end
                default: begin cur = h_out; modv = 24; end
            endcase
            upn = (target - cur + modv) % modv;
            if (upn <= modv / 2)
                for (k = 0; k < upn; k = k + 1) press(1, PRESS_MS);
            else
                for (k = 0; k < modv - upn; k = k + 1) press(2, PRESS_MS);
            case (field)
                0: cur = s_out;
                1: cur = m_out;
                default: cur = h_out;
            endcase
            check(cur === target, "adjust dat gia tri muc tieu");
        end
    endtask

    // Watchdog
    initial begin
        #60_000_000;   // 60 s mô phỏng
        $display("TIMEOUT: testbench bi treo");
        $finish;
    end

    // -------------------------------------------------------------------------
    // Kịch bản kiểm tra
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("hms_timer_tb.vcd");
        $dumpvars(0, tb_hms_timer);
        $timeformat(-3, 3, " ms", 12);

        errors = 0; checks = 0; chk_en = 1'b0;
        rst_n = 1'b0; sel_in = 1'b0; up_in = 1'b0; down_in = 1'b0;

        // ---- T1: reset ------------------------------------------------------
        repeat (5) @(posedge clk);
        #0.1;
        check({h_out, m_out, s_out} === {5'd0, 6'd0, 6'd0}, "T1 reset: 00:00:00");
        check(dut.fsm_normal === 1'b1,                      "T1 reset: FSM o NORMAL");
        @(negedge clk) rst_n = 1'b1;
        repeat (4) @(posedge clk);
        chk_en = 1'b1;

        // ---- T2: đếm giây ---------------------------------------------------
        for (i = 1; i <= 3; i = i + 1) begin
            wait_tick;
            check(s_out === i, "T2 giay tang 1 moi 1 s");
        end

        // ---- T3: nút ở NORMAL ----------------------------------------------
        wait_tick;
        snap = s_out;
        press(1, 40);                 // up ở NORMAL: bỏ qua
        press(2, 40);                 // down ở NORMAL: bỏ qua
        check(s_out === snap && dut.fsm_normal === 1'b1, "T3 up/down o NORMAL khong doi gio");
        press(0, 10);                 // nhiễu sel 10 ms
        check(dut.fsm_normal === 1'b1,                   "T3 nhieu sel 10 ms bi loc");
        press(0, 1000);               // nhấn sel 1 s (< 3 s)
        check(dut.fsm_normal === 1'b1,                   "T3 nhan sel ngan (1 s) khong vao edit");

        // ---- T4: phiên chỉnh 1: đặt 23:59:58 rồi kiểm tra tràn --------------
        press(0, LONG_MS);            // giữ sel > 3 s
        check(dut.fsm_edit_en_sec === 1'b1 && dut.fsm_normal === 1'b0, "T4 giu sel >3 s vao edit SEC");

        snap = s_out;                 // giá trị edit đã chốt
        wait_tick;
        check(s_out === snap && dut.sec_rt !== s_out, "T4 gio hien thi dung yen khi edit, bo dem van chay");

        adjust(0, 58);
        press(0, PRESS_MS);
        check(dut.fsm_edit_en_min === 1'b1, "T4 sel: SEC -> MIN");
        adjust(1, 59);
        press(0, PRESS_MS);
        check(dut.fsm_edit_en_hour === 1'b1, "T4 sel: MIN -> HOUR");
        adjust(2, 23);

        wait_tick;                    // đồng bộ để không trùng tick khi nạp
        press(0, PRESS_MS);           // sel ở HOUR: nạp giá trị, về NORMAL
        repeat (5) @(posedge clk); #0.1;
        check(dut.fsm_normal === 1'b1, "T4 sel o HOUR -> ve NORMAL");
        check({h_out, m_out, s_out} === {5'd23, 6'd59, 6'd58}, "T4 nap 23:59:58 dung");

        wait_tick;
        check({h_out, m_out, s_out} === {5'd23, 6'd59, 6'd59}, "T4 tick -> 23:59:59");
        wait_tick;
        check({h_out, m_out, s_out} === {5'd0, 6'd0, 6'd0},    "T4 tick -> 00:00:00 (tran giay/phut/gio)");

        // ---- T5: phiên chỉnh 2: wrap up/down, nhiễu, timeout ----------------
        press(0, LONG_MS);
        check(dut.fsm_edit_en_sec === 1'b1, "T5 vao edit SEC lan 2");

        adjust(0, 0);
        press(2, PRESS_MS);
        check(s_out === 59, "T5 giay: down tu 0 -> 59");
        press(1, PRESS_MS);
        check(s_out === 0,  "T5 giay: up tu 59 -> 0");
        press(1, 5);
        check(s_out === 0,  "T5 nhieu up 5 ms bi loc");

        press(0, PRESS_MS);
        adjust(1, 0);
        press(2, PRESS_MS);
        check(m_out === 59, "T5 phut: down tu 0 -> 59");
        press(1, PRESS_MS);
        check(m_out === 0,  "T5 phut: up tu 59 -> 0");

        press(0, PRESS_MS);
        check(dut.fsm_edit_en_hour === 1'b1, "T5 sang HOUR");
        adjust(2, 0);
        press(2, PRESS_MS);
        check(h_out === 23, "T5 gio: down tu 0 -> 23");
        press(1, PRESS_MS);
        check(h_out === 0,  "T5 gio: up tu 23 -> 0");

        // Timeout 5 s, có nhấn nút giữa chừng thì đếm lại từ đầu
        wait_tick;
        press(1, PRESS_MS);                       // hoạt động -> cnt = 0
        wait_tick; wait_tick; wait_tick;          // 3 s rảnh
        check(dut.fsm_normal === 1'b0, "T6 3 s ranh: van o edit");
        press(2, PRESS_MS);                       // nhấn nút -> phải reset bộ đếm timeout
        wait_tick; wait_tick; wait_tick; wait_tick;
        check(dut.fsm_normal === 1'b0, "T6 nhan nut reset timeout: 4 s sau van o edit");
        wait_tick;                                // giây rảnh thứ 5
        check(dut.fsm_normal === 1'b1, "T6 5 s khong thao tac -> timeout ve NORMAL");
        check({h_out, m_out, s_out} === {m_h, m_m, m_s} && s_out !== 0,
              "T6 timeout: bo chinh sua, dong ho chay tiep");

        // ---- T7: reset bất đồng bộ khi đang chạy ----------------------------
        @(negedge clk) rst_n = 1'b0;
        #0.1;
        check({h_out, m_out, s_out} === {5'd0, 6'd0, 6'd0} && dut.fsm_normal === 1'b1,
              "T7 reset async: 00:00:00, NORMAL");
        repeat (5) @(posedge clk);
        @(negedge clk) rst_n = 1'b1;
        wait_tick;
        check(s_out === 1, "T7 sau reset dem lai tu 0 -> 1");

        // ---- Kết quả --------------------------------------------------------
        $display("================================================");
        if (errors == 0)
            $display("TAT CA %0d KIEM TRA DEU PASS", checks);
        else
            $display("CO %0d LOI (tren %0d kiem tra truc tiep)", errors, checks);
        $display("================================================");
        $finish;
    end

endmodule
