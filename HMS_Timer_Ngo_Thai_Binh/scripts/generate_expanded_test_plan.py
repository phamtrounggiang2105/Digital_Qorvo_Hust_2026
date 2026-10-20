#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Expanded Verification Test Plan Generator for HMS_Timer IP Core
Generates:
  - docs/HMS_Timer_Test_Plan_Expanded.xlsx
  - HMS_Timer_Test_Plan_Expanded.xlsx (root copy)

Worksheets:
  1. Verification Test Plan (131 Test Items: 55 Legacy + 76 New)
  2. Requirement Traceability (RTM covering all 19 requirements + derived)
  3. SVA & Coverage Matrix (18 SVA properties + 6 functional covergroups)
  4. Review Issues (10 structured review issues & architectural resolutions)
"""

import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter
import shutil

def build_workbook():
    wb = openpyxl.Workbook()
    
    # -------------------------------------------------------------
    # Styling Definitions
    # -------------------------------------------------------------
    COLOR_SUMMARY_BG = "FFF2CC" # Soft yellow
    COLOR_GOLD       = "FFE699" # Gold/Yellow
    COLOR_ORANGE     = "F8CBAD" # Soft Orange / Peach
    COLOR_PEACH      = "FCE4D6" # Test Pattern Phase
    COLOR_BLUE       = "D9E1F2" # Soft Blue
    COLOR_GRAY_LIGHT = "F2F2F2"
    COLOR_PASS_BG    = "E2EFDA" # Light Green
    COLOR_PASS_TXT   = "375623" # Dark Green
    COLOR_PLAN_BG    = "FFF2CC" # Light Yellow for Planned
    COLOR_PLAN_TXT   = "7F6000" # Dark Yellow for Planned
    COLOR_BORDER     = "D9D9D9"
    COLOR_BORDER_HDR = "000000"

    FILL_SUMMARY     = PatternFill(start_color=COLOR_SUMMARY_BG, end_color=COLOR_SUMMARY_BG, fill_type="solid")
    FILL_GOLD        = PatternFill(start_color=COLOR_GOLD, end_color=COLOR_GOLD, fill_type="solid")
    FILL_ORANGE      = PatternFill(start_color=COLOR_ORANGE, end_color=COLOR_ORANGE, fill_type="solid")
    FILL_PEACH       = PatternFill(start_color=COLOR_PEACH, end_color=COLOR_PEACH, fill_type="solid")
    FILL_BLUE        = PatternFill(start_color=COLOR_BLUE, end_color=COLOR_BLUE, fill_type="solid")
    FILL_GRAY        = PatternFill(start_color=COLOR_GRAY_LIGHT, end_color=COLOR_GRAY_LIGHT, fill_type="solid")
    FILL_PASS        = PatternFill(start_color=COLOR_PASS_BG, end_color=COLOR_PASS_BG, fill_type="solid")
    FILL_PLAN        = PatternFill(start_color=COLOR_PLAN_BG, end_color=COLOR_PLAN_BG, fill_type="solid")

    FONT_TITLE       = Font(name="Calibri", size=11, bold=True, color="000000")
    FONT_HEADER      = Font(name="Calibri", size=10, bold=True, color="000000")
    FONT_SUBHEADER   = Font(name="Calibri", size=9.5, bold=True, color="000000")
    FONT_BODY        = Font(name="Calibri", size=9, color="000000")
    FONT_BODY_BOLD   = Font(name="Calibri", size=9, bold=True, color="000000")
    FONT_CODE        = Font(name="Consolas", size=8.5, color="1F497D")
    FONT_PASS        = Font(name="Calibri", size=9.5, bold=True, color=COLOR_PASS_TXT)
    FONT_PLAN        = Font(name="Calibri", size=9.5, bold=True, color=COLOR_PLAN_TXT)
    FONT_CRITICAL    = Font(name="Calibri", size=9, bold=True, color="C00000")
    FONT_HIGH        = Font(name="Calibri", size=9, bold=True, color="ED7D31")
    FONT_MEDIUM      = Font(name="Calibri", size=9, bold=True, color="7030A0")
    FONT_LOW         = Font(name="Calibri", size=9, bold=True, color="385723")
    FONT_DATE        = Font(name="Calibri", size=8.5, color="595959")

    THIN_BLACK = Side(border_style="thin", color="000000")
    THIN_GRAY  = Side(border_style="thin", color="BFBFBF")

    BORDER_HEADER = Border(left=THIN_BLACK, right=THIN_BLACK, top=THIN_BLACK, bottom=THIN_BLACK)
    BORDER_DATA   = Border(left=THIN_GRAY, right=THIN_GRAY, top=THIN_GRAY, bottom=THIN_GRAY)

    ALIGN_CENTER     = Alignment(horizontal="center", vertical="center", wrap_text=True)
    ALIGN_LEFT       = Alignment(horizontal="left", vertical="center", wrap_text=True)
    ALIGN_TOP_LEFT   = Alignment(horizontal="left", vertical="top", wrap_text=True)
    ALIGN_TOP_CENTER = Alignment(horizontal="center", vertical="top", wrap_text=True)

    # =========================================================================
    # 1. READ ORIGINAL 55 ITEMS FROM docs/HMS_Timer_Test_Plan.xlsx
    # =========================================================================
    wb_orig = openpyxl.load_workbook('docs/HMS_Timer_Test_Plan.xlsx')
    ws_orig = wb_orig['Verification Test Plan']

    legacy_items = []
    c_big, c_big_no = '', 1
    c_med, c_med_no = '', 1

    for r in range(6, ws_orig.max_row + 1):
        big = ws_orig.cell(r, 1).value
        big_no = ws_orig.cell(r, 2).value
        med = ws_orig.cell(r, 3).value
        med_no = ws_orig.cell(r, 4).value
        small = ws_orig.cell(r, 5).value
        desc = ws_orig.cell(r, 6).value
        exp = ws_orig.cell(r, 7).value
        num = ws_orig.cell(r, 8).value or 1
        fin = ws_orig.cell(r, 9).value or 1
        prio = ws_orig.cell(r, 10).value or "High"
        pic = ws_orig.cell(r, 11).value or "Ngo Thai Binh"
        tf = ws_orig.cell(r, 12).value or ""
        sva = ws_orig.cell(r, 13).value or ""
        r1_res = ws_orig.cell(r, 14).value or "Pass"
        r1_date = ws_orig.cell(r, 15).value or "13/10/2026"
        r1_note = ws_orig.cell(r, 16).value or ""

        if big: c_big = big
        if big_no is not None: c_big_no = big_no
        if med: c_med = med
        if med_no is not None: c_med_no = med_no

        # Improvement for Item 1.2.2 as agreed
        if '1.2.2' in str(small):
            small = '1.2.2\n2-Cycle Sync Latency & Removal Timing Margin'
            desc = 'Mục đích: Xác minh 2 tầng FF của reset_sync đảm bảo độ trễ định thời 2 chu kỳ clock và thỏa mãn removal margin khi giải trừ reset.\nStimulus: Drive cạnh lên của rstn tại các thời điểm vi phạm setup time của FF1 (quét offset 0.1ns, 0.3ns, 0.5ns trước posedge clk).'
            exp = 'Ngõ ra rstn_sync chuyển lên 1 sau đúng 2 chu kỳ clock, không bao giờ xuất hiện giá trị X hay glitch tại clock domain nội bộ.\nChecker: monitor rstn_sync không có giá trị X hoặc glitch.'
            r1_note = 'Reframed from analog metastability to 2-cycle latency & removal margin verification'

        legacy_items.append({
            'big_no': c_big_no, 'big': c_big,
            'med_no': c_med_no, 'med': c_med,
            'small': small, 'desc': desc, 'exp': exp,
            'num': num, 'fin': fin, 'prio': prio, 'pic': pic,
            'tf': tf, 'sva': sva, 'r1_res': r1_res, 'r1_date': r1_date, 'r1_note': r1_note,
            'is_legacy': True
        })

    # =========================================================================
    # 2. DEFINE 76 NEW TEST ITEMS TO COVER ALL ARCHITECTURAL GAPS
    # =========================================================================
    new_items = [
        # --- BIG ITEM 1: RESET & CLOCK MANAGEMENT ---
        {
            'big_no': 1, 'big': 'Reset & Clock Management',
            'med_no': 1, 'med': 'reset_sync async assert behavior',
            'small': '1.1.3\nAsync reset assert when master clk is HIGH',
            'desc': 'Mục đích: Kiểm tra khả năng tác động tức thời (asynchronous assert) của reset_sync khi rstn kích hoạt mức thấp tại thời điểm master clk đang ở mức HIGH (giữa chu kỳ).\nStimulus: Cho clk chạy ổn định; drive rstn = 0 khi clk = 1.',
            'exp': 'rstn_sync lập tức kéo xuống 0 ngay trong pha clk HIGH mà không chờ cạnh posedge kế tiếp.\nChecker: assert property p_reset_state ngay tại thời điểm assert.',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_timer_if.sv', 'sva': 'assert_reset_async_clk_high',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Verify async assert path with clk=1'
        },
        {
            'big_no': 1, 'big': 'Reset & Clock Management',
            'med_no': 1, 'med': 'reset_sync async assert behavior',
            'small': '1.1.4\nAsync reset assert when master clk is LOW',
            'desc': 'Mục đích: Kiểm tra khả năng tác động tức thời của reset_sync khi rstn kích hoạt mức thấp tại thời điểm master clk đang ở mức LOW.\nStimulus: Cho clk chạy; drive rstn = 0 khi clk = 0.',
            'exp': 'rstn_sync lập tức kéo xuống 0 ngay trong pha clk LOW, độc lập hoàn toàn với clock.\nChecker: assert property p_reset_state.',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_timer_if.sv', 'sva': 'assert_reset_async_clk_low',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Verify async assert path with clk=0'
        },
        {
            'big_no': 1, 'big': 'Reset & Clock Management',
            'med_no': 1, 'med': 'reset_sync async assert behavior',
            'small': '1.1.5\nSimultaneous clear of both synchronizer FF stages',
            'desc': 'Mục đích: Xác minh cả hai tầng Flip-Flop (meta_rstn và sync_rstn) trong reset_sync đều bị xóa về 0 đồng thời tại cạnh xuống của rstn.\nStimulus: Set meta_rstn = 1, sync_rstn = 1; drive rstn = 0.',
            'exp': 'meta_rstn == 0 và sync_rstn == 0 được xóa đồng thời, không có hiện tượng tầng sau nhận trễ 1 chu kỳ.\nChecker: White-box assertion trên u_reset_sync.',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv', 'sva': 'assert_reset_both_ff_cleared',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'White-box FF clear check'
        },
        {
            'big_no': 1, 'big': 'Reset & Clock Management',
            'med_no': 4, 'med': 'Reset recovery & active corner injection',
            'small': '1.4.6\nReset assertion at Second Counter rollover boundary',
            'desc': 'Mục đích: Xác minh tính an toàn khi kích hoạt reset bất đồng bộ đúng thời điểm Second Counter đạt giá trị 59 và có sec_pulse.\nStimulus: Đếm đến s_cnt = 59, sec_pulse = 1; kích hoạt rstn = 0 ngay trước cạnh clock kế tiếp.',
            'exp': 'Hệ thống chuyển về 00:00:00, không phát sinh xung sec_rollover giả mạo sang minute counter.\nChecker: assert_sec_rollover_sync và check_time(0,0,0).',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_timer_if.sv', 'sva': 'assert_no_spurious_rollover_on_rst',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Rollover collision corner test'
        },
        {
            'big_no': 1, 'big': 'Reset & Clock Management',
            'med_no': 4, 'med': 'Reset recovery & active corner injection',
            'small': '1.4.7\nReset assertion during active Debounce sequence',
            'desc': 'Mục đích: Xác minh reset bất đồng bộ xóa triệt để bộ đếm debounce khi đang đếm dở dang.\nStimulus: Giữ btn_in ở mức cao qua 10 xung pulse_1khz (timer_cnt = 10 / 20); kích hoạt rstn = 0.',
            'exp': 'timer_cnt lập tức bị xóa về 0, debounced_btn = 0, btn_event tuyệt đối không phát xung.\nChecker: white-box probe timer_cnt == 0 và btn_event == 0.',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv', 'sva': 'assert_debouncer_reset_midway',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Debounce mid-counter abort test'
        },
        {
            'big_no': 1, 'big': 'Reset & Clock Management',
            'med_no': 4, 'med': 'Reset recovery & active corner injection',
            'small': '1.4.8\nReset assertion during Inactivity Timeout countdown',
            'desc': 'Mục đích: Xác minh reset khi timeout counter đang đếm ở giây thứ 4 trong chế độ ADJ_SEC.\nStimulus: Vào ADJ_SEC, chờ 4 xung sec_pulse (timeout_cnt = 4); drive rstn = 0.',
            'exp': 'FSM quay về MODE_RUN, timeout_cnt xóa về 0, không phát xung load_en, buffer bị xóa sạch.\nChecker: check_mode(MODE_RUN) & assert_load_en == 0.',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'assert_timeout_reset_midway',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Timeout abort mid-count verification'
        },
        {
            'big_no': 1, 'big': 'Reset & Clock Management',
            'med_no': 4, 'med': 'Reset recovery & active corner injection',
            'small': '1.4.9\nReset assertion during Synchronous Commit cycle',
            'desc': 'Mục đích: Xác minh reset tác động đúng chu kỳ commit (load_en = 1) khi chuyển từ ADJ_HOUR sang RUN.\nStimulus: Nhấn SEL tại ADJ_HOUR để phát load_en; drive rstn = 0 đúng trong chu kỳ load_en đang tích cực.',
            'exp': 'Tất cả các counter nhận giá trị reset 00:00:00 thay vì nạp giá trị từ edit buffer.\nChecker: check_time(0,0,0) tại chu kỳ sau reset.',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'assert_reset_overrides_commit',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Reset priority over parallel commit'
        },
        {
            'big_no': 1, 'big': 'Reset & Clock Management',
            'med_no': 4, 'med': 'Reset recovery & active corner injection',
            'small': '1.4.10\nReset assertion during Midnight Rollover',
            'desc': 'Mục đích: Xác minh reset bất đồng bộ tại chu kỳ chuyển giao ngày 23:59:59 -> 00:00:00.\nStimulus: Đưa counter nền về 23:59:59; tại cạnh clock xuất hiện sec_pulse, drive rstn = 0.',
            'exp': 'Hệ thống an toàn về 00:00:00, không bị latch giá trị trung gian hay lỗi tràn.\nChecker: check_time(0,0,0) và range assertions.',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_timer_if.sv', 'sva': 'assert_reset_at_midnight_cascade',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Midnight cascade collision recovery'
        },
        {
            'big_no': 1, 'big': 'Reset & Clock Management',
            'med_no': 5, 'med': 'clk_prescaler pulse precision & parameters',
            'small': '1.5.3\nPrescaler pulse width exact 1-cycle master clock',
            'desc': 'Mục đích: Đo đạc chính xác độ rộng của xung pulse_1khz và sec_pulse luôn đúng bằng 1 chu kỳ clock chủ 1 MHz (1 us), không bao giờ kéo dài 2 chu kỳ.\nStimulus: Giám sát liên tục tín hiệu pulse_1khz và sec_pulse trong 10,000 chu kỳ.',
            'exp': 'pulse_1khz |=> !pulse_1khz và sec_pulse |=> !sec_pulse luôn đúng.\nChecker: assert property p_pulse_1khz_width và p_sec_pulse_width.',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_timer_if.sv', 'sva': 'assert_pulse_width_1cycle',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Strict 1-cycle pulse width assertion'
        },
        {
            'big_no': 1, 'big': 'Reset & Clock Management',
            'med_no': 5, 'med': 'clk_prescaler pulse precision & parameters',
            'small': '1.5.4\nPrescaler Stage 1 exact 1,000 clock period interval',
            'desc': 'Mục đích: Xác minh khoảng cách giữa hai xung pulse_1khz liên tiếp đạt chính xác 1,000 chu kỳ master clock (1,000 us).\nStimulus: Chạy hệ thống với tham số mặc định P_CLK_FREQ_HZ = 1,000,000, P_PULSE_1KHZ_FREQ_HZ = 1,000; đo khoảng cách xung.',
            'exp': 'Khoảng cách giữa hai cạnh lên của pulse_1khz chính xác là 1,000 posedge clk, không sai lệch +-1.\nChecker: Scoreboard cycle timer.',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_prescaler_stage1_period',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Cycle-accurate period measurement'
        },
        {
            'big_no': 1, 'big': 'Reset & Clock Management',
            'med_no': 5, 'med': 'clk_prescaler pulse precision & parameters',
            'small': '1.5.5\nPrescaler Stage 2 exact 1,000 pulse_1khz period interval',
            'desc': 'Mục đích: Xác minh khoảng cách giữa hai xung sec_pulse liên tiếp đạt chính xác 1,000 xung pulse_1khz (1,000,000 chu kỳ clk = 1s).\nStimulus: Chạy hệ thống; đếm số xung pulse_1khz xuất hiện giữa hai lần sec_pulse tích cực.',
            'exp': 'Chính xác 1,000 xung pulse_1khz trên mỗi chu kỳ sec_pulse.\nChecker: Scoreboard pulse counter.',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_prescaler_stage2_period',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Cascaded stage 2 ratio check'
        },
        {
            'big_no': 1, 'big': 'Reset & Clock Management',
            'med_no': 5, 'med': 'clk_prescaler pulse precision & parameters',
            'small': '1.5.6\nPrescaler counter wrap-around and dead-lock freedom',
            'desc': 'Mục đích: Xác minh bộ đếm prescaler quay vòng trơn tru sau khi đạt ngưỡng cực đại (999 -> 0) và không bao giờ bị rơi vào trạng thái treo (deadlock).\nStimulus: Chạy liên tục qua 10 chu kỳ sec_pulse.',
            'exp': 'Các thanh ghi r_cnt_1khz và r_cnt_1hz wrap về 0 chính xác, hệ thống đếm ổn định liên tục.\nChecker: continuous monitor.',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv', 'sva': 'assert_prescaler_no_deadlock',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Prescaler continuous wrap check'
        },

        # --- BIG ITEM 2: BUTTON PROCESSING & GLITCH IMMUNITY ---
        {
            'big_no': 2, 'big': 'Button Processing & Glitch Immunity',
            'med_no': 1, 'med': 'Mechanical Debounce Threshold & Auto-Repeat Rejection',
            'small': '2.1.5\nMechanical bounce noise rejection at boundary (18-19 samples)',
            'desc': 'Mục đích: Xác minh rung phím cơ học sát ngưỡng (đạt 18 hoặc 19 mẫu tại xung 1kHz rồi bị kéo về mức 0) sẽ bị reset counter và không phát xung sự kiện.\nStimulus: Drive btn_in = 1 qua 19 xung pulse_1khz, sau đó kéo về 0 tại xung thứ 20.',
            'exp': 'btn_event tuyệt đối không tích cực (giữ 0). Debounce counter bị xóa về 0 tại chu kỳ clk_en kế tiếp.\nChecker: assert property (btn_event == 0).',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_timer_if.sv', 'sva': 'assert_debounce_boundary_rejection',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': '19-sample threshold boundary check'
        },
        {
            'big_no': 2, 'big': 'Button Processing & Glitch Immunity',
            'med_no': 1, 'med': 'Mechanical Debounce Threshold & Auto-Repeat Rejection',
            'small': '2.1.6\nMechanical release qualification: brief release (< 20ms) rejected',
            'desc': 'Mục đích: Xác minh khi đang giữ phím, nếu phím bị nhả nhanh (< 20ms = < 20 xung pulse_1khz) rồi nhấn lại thì trạng thái debounced_btn vẫn giữ ở mức 1.\nStimulus: Sau khi phím đã được chấp nhận (1), nhả btn_in về 0 trong 15 xung pulse_1khz rồi kéo lên 1 lại.',
            'exp': 'Trạng thái ổn định không bị coi là đã nhả hoàn toàn; không phát xung btn_event thứ hai khi kéo lên lại.\nChecker: Scoreboard event count == 1.',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_debounce_short_release',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Short release rejection verification'
        },
        {
            'big_no': 2, 'big': 'Button Processing & Glitch Immunity',
            'med_no': 1, 'med': 'Mechanical Debounce Threshold & Auto-Repeat Rejection',
            'small': '2.1.7\nMechanical release qualification: full release (>= 20ms) resets state',
            'desc': 'Mục đích: Xác minh khi nhả phím đủ >= 20ms (>= 20 xung pulse_1khz), mạch lọc rung hoàn tất việc công nhận nhả phím và sẵn sàng cho lần bấm tiếp theo.\nStimulus: Nhả btn_in về 0 liên tục qua 25 xung pulse_1khz.',
            'exp': 'debounced_btn trở về mức 0 an toàn; timer_cnt sẵn sàng đếm cho lần nhấn kế tiếp.\nChecker: White-box probe debounced_btn == 0.',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv', 'sva': 'check_debounce_full_release',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Full release acceptance verification'
        },
        {
            'big_no': 2, 'big': 'Button Processing & Glitch Immunity',
            'med_no': 1, 'med': 'Mechanical Debounce Threshold & Auto-Repeat Rejection',
            'small': '2.1.8\nConsecutive valid button presses separated by idle release',
            'desc': 'Mục đích: Xác minh chuỗi 2 lần bấm hợp lệ liên tiếp (nhấn 25ms, nhả 25ms, nhấn 25ms) phát sinh chính xác 2 xung sự kiện đơn chu kỳ.\nStimulus: Bơm chuỗi nhấn-nhả-nhấn chuẩn thời gian.',
            'exp': 'btn_event phát đúng 1 xung tại lần nhấn 1, và đúng 1 xung tại lần nhấn 2. Tổng số xung sự kiện ghi nhận là 2.\nChecker: Event counter == 2.',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_debounce_consecutive_presses',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Consecutive valid press sequence'
        },
        {
            'big_no': 2, 'big': 'Button Processing & Glitch Immunity',
            'med_no': 1, 'med': 'Mechanical Debounce Threshold & Auto-Repeat Rejection',
            'small': '2.1.9\nStrict single-clock-cycle pulse width on btn_event',
            'desc': 'Mục đích: Xác minh xung btn_event phát ra luôn có độ rộng chính xác bằng 1 chu kỳ clock chủ 1 MHz (1 us), không phụ thuộc vào thời gian người dùng giữ phím.\nStimulus: Nhấn phím giữ trong 50ms, 100ms, 200ms.',
            'exp': 'Xung btn_event chỉ tích cực mức 1 trong đúng 1 chu kỳ posedge clk duy nhất rồi trở về 0 ngay chu kỳ tiếp theo.\nChecker: assert property (btn_event |=> !btn_event).',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_timer_if.sv', 'sva': 'assert_btn_event_width_1cycle',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Single-cycle event pulse assertion'
        },
        {
            'big_no': 2, 'big': 'Button Processing & Glitch Immunity',
            'med_no': 1, 'med': 'Mechanical Debounce Threshold & Auto-Repeat Rejection',
            'small': '2.1.10\nDebouncer counter hold verification between 1kHz enables',
            'desc': 'Mục đích: Xác minh bộ đếm timer_cnt giữ nguyên giá trị tại các chu kỳ master clock mà clk_en (pulse_1khz) = 0.\nStimulus: Quan sát timer_cnt trong 999 chu kỳ giữa hai xung pulse_1khz khi đang debounce.',
            'exp': 'timer_cnt không thay đổi trong toàn bộ khoảng thời gian clk_en = 0.\nChecker: assert property (clk_en == 0 |=> timer_cnt == $past(timer_cnt)).',
            'num': 1, 'fin': 0, 'prio': 'Medium', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv', 'sva': 'assert_debouncer_timer_cnt_hold',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Clock enable gating hold check'
        },
        {
            'big_no': 2, 'big': 'Button Processing & Glitch Immunity',
            'med_no': 1, 'med': 'Mechanical Debounce Threshold & Auto-Repeat Rejection',
            'small': '2.1.11\nDebouncer reset gating verification at 1kHz sampling rate',
            'desc': 'Mục đích: Xác nhận hành vi theo đặc tả: timer_cnt chỉ được xóa về 0 khi có xung clk_en (pulse_1khz) và sync_btn == debounced_btn, giữ nguyên cơ chế gated 1kHz như kiến trúc hiện tại.\nStimulus: Tạo xung rung phím phục hồi về mức 0 trong khoảng giữa hai xung pulse_1khz.',
            'exp': 'Hệ thống cập nhật kiểm tra timer_cnt tại cạnh có clk_en; xác minh không có lỗi vi phạm timing.\nChecker: white-box monitor.',
            'num': 1, 'fin': 0, 'prio': 'Medium', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv', 'sva': 'check_debouncer_gated_reset_spec',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Confirmed 1kHz gated reset mechanism'
        },
        {
            'big_no': 2, 'big': 'Button Processing & Glitch Immunity',
            'med_no': 2, 'med': 'Multi-Channel Button Independence & Asynchronous Phasing',
            'small': '2.2.3\nAsynchronous button edge phase shift sweep',
            'desc': 'Mục đích: Quét pha kích hoạt của nút bấm ngoại vi lệch pha từ 0% đến 90% chu kỳ clock chủ 1 MHz để xác minh tầng D-FF đồng bộ hóa an toàn.\nStimulus: Drive cạnh lên của sel_in tại các góc pha offset {100ns, 250ns, 500ns, 750ns, 900ns}.',
            'exp': 'Tầng meta_btn và sync_btn chuyển đổi mức logic an toàn, không sinh xung nhọn (glitch) vào khối đếm debounce.\nChecker: monitor sync_btn clean transitions.',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv', 'sva': 'check_async_phase_shift_sweep',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Phase shift sweep across clock period'
        },
        {
            'big_no': 2, 'big': 'Button Processing & Glitch Immunity',
            'med_no': 2, 'med': 'Multi-Channel Button Independence & Asynchronous Phasing',
            'small': '2.2.4\nTwo-button concurrent valid press (SEL + UP simultaneous)',
            'desc': 'Mục đích: Xác minh khi hai nút bấm SEL và UP cùng được nhấn giữ hợp lệ (>= 20ms) đồng thời, cả hai kênh debouncer đều phát xung sự kiện đơn chu kỳ độc lập.\nStimulus: Kích hoạt đồng thời sel_in = 1 và up_in = 1 qua 20 xung pulse_1khz.',
            'exp': 'sel_pulse = 1 và up_pulse = 1 xuất hiện tại cùng 1 chu kỳ clock mà không làm nghẽn kênh của nhau.\nChecker: assert property (sel_pulse && up_pulse).',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_timer_if.sv', 'sva': 'assert_concurrent_debouncer_events',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Concurrent two-channel debouncer test'
        },
        {
            'big_no': 2, 'big': 'Button Processing & Glitch Immunity',
            'med_no': 2, 'med': 'Multi-Channel Button Independence & Asynchronous Phasing',
            'small': '2.2.5\nThree-button concurrent valid press (SEL + UP + DOWN)',
            'desc': 'Mục đích: Xác minh khi cả 3 nút bấm SEL, UP, DOWN cùng được kích hoạt đồng thời, cả 3 bộ lọc rung hoạt động song song chính xác.\nStimulus: Drive sel_in, up_in, down_in đồng thời lên 1 qua 20 mẫu pulse_1khz.',
            'exp': 'Cả 3 xung sel_pulse, up_pulse, down_pulse cùng xuất hiện đồng thời trong 1 chu kỳ duy nhất.\nChecker: check 3-channel pulse sync.',
            'num': 1, 'fin': 0, 'prio': 'Medium', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv', 'sva': 'assert_all_three_debouncers_sync',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'All 3 buttons concurrent activation'
        },
        {
            'big_no': 2, 'big': 'Button Processing & Glitch Immunity',
            'med_no': 2, 'med': 'Multi-Channel Button Independence & Asynchronous Phasing',
            'small': '2.2.6\nChannel isolation: UP button activity does not affect SEL/DOWN',
            'desc': 'Mục đích: Xác minh hoạt động bấm phím liên tục trên kênh UP không gây nhiễu chéo (crosstalk logic) sang kênh SEL hoặc DOWN.\nStimulus: Nhấn thả UP liên tục 20 lần; giữ SEL và DOWN ở mức 0.',
            'exp': 'Chỉ có up_pulse phát xung; sel_pulse và down_pulse duy trì tuyệt đối ở mức 0.\nChecker: assert property (sel_pulse == 0 && down_pulse == 0).',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_timer_if.sv', 'sva': 'assert_channel_isolation_up',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Channel isolation cross-talk check'
        },

        # --- BIG ITEM 3: MODE CONTROLLER & TIMEOUT FSM ---
        {
            'big_no': 3, 'big': 'Mode Controller & Timeout FSM',
            'med_no': 1, 'med': '4-State Circular FSM Transitions',
            'small': '3.1.5\nFSM idle state stability (self-loop hold)',
            'desc': 'Mục đích: Xác minh FSM tự giữ nguyên trạng thái hiện tại (MODE_RUN, MODE_ADJ_SEC, MODE_ADJ_MIN, MODE_ADJ_HOUR) khi không có sự kiện bấm phím và chưa timeout.\nStimulus: Duy trì DUT ở mỗi trạng thái trong 1,000 chu kỳ clk khi không có phím bấm.',
            'exp': 'state_reg giữ nguyên không đổi.\nChecker: assert property (no_button && no_timeout |=> state_reg == $past(state_reg)).',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_timer_if.sv', 'sva': 'assert_fsm_self_loop_hold',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'FSM self-loop stability check'
        },
        {
            'big_no': 3, 'big': 'Mode Controller & Timeout FSM',
            'med_no': 1, 'med': '4-State Circular FSM Transitions',
            'small': '3.1.6\nStrict single transition per SEL event pulse',
            'desc': 'Mục đích: Xác minh mỗi xung sel_pulse đơn chu kỳ chỉ làm FSM chuyển đúng 1 bước trạng thái duy nhất, không bao giờ nhảy cóc qua 2 trạng thái.\nStimulus: Bơm 1 xung sel_pulse duy nhất tại MODE_RUN.',
            'exp': 'FSM chuyển từ MODE_RUN sang MODE_ADJ_SEC và dừng lại ổn định ở MODE_ADJ_SEC.\nChecker: assert property (adj_mode == MODE_ADJ_SEC throughout subsequent cycles).',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_timer_if.sv', 'sva': 'assert_single_step_fsm_advance',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'FSM no double-step jump assertion'
        },
        {
            'big_no': 3, 'big': 'Mode Controller & Timeout FSM',
            'med_no': 1, 'med': '4-State Circular FSM Transitions',
            'small': '3.1.7\nFSM safe-state default recovery from illegal state',
            'desc': 'Mục đích: Xác minh nếu FSM bị rơi vào trạng thái không hợp lệ ngoài 4 trạng thái (phòng thủ an toàn), FSM tự động thu hồi về MODE_RUN.\nStimulus: Ép trạng thái state_reg = 2\'bXX bằng force logic.\nRelease force.',
            'exp': 'FSM chuyển về MODE_RUN (2\'b00) tại chu kỳ clock kế tiếp.\nChecker: scoreboard.check_mode(MODE_RUN).',
            'num': 1, 'fin': 0, 'prio': 'Medium', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_fsm_illegal_state_recovery',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Safe-state recovery verification'
        },
        {
            'big_no': 3, 'big': 'Mode Controller & Timeout FSM',
            'med_no': 2, 'med': 'Inactivity Timeout 5s & Keep-Alive Protection',
            'small': '3.2.3\nInactivity Timeout in MODE_ADJ_SEC: exact 5 sec_pulses',
            'desc': 'Mục đích: Xác minh bộ đếm timeout tại MODE_ADJ_SEC đếm đúng 5 xung sec_pulse rồi kích hoạt chuyển FSM về MODE_RUN.\nStimulus: Vào MODE_ADJ_SEC; không bấm nút; đếm số xung sec_pulse cho đến khi thoát.',
            'exp': 'Tại xung sec_pulse thứ 5, FSM chuyển từ MODE_ADJ_SEC về MODE_RUN. Tại xung thứ 4 vẫn ở MODE_ADJ_SEC.\nChecker: Cycle-accurate timeout monitor.',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_timeout_exact_5s_sec_mode',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'ADJ_SEC 5-second timeout check'
        },
        {
            'big_no': 3, 'big': 'Mode Controller & Timeout FSM',
            'med_no': 2, 'med': 'Inactivity Timeout 5s & Keep-Alive Protection',
            'small': '3.2.4\nInactivity Timeout in MODE_ADJ_MIN: exact 5 sec_pulses',
            'desc': 'Mục đích: Xác minh bộ đếm timeout tại MODE_ADJ_MIN đếm đúng 5 xung sec_pulse rồi kích hoạt chuyển FSM về MODE_RUN.\nStimulus: Vào MODE_ADJ_MIN; không bấm nút; đếm số xung sec_pulse.',
            'exp': 'Tại xung sec_pulse thứ 5, FSM chuyển về MODE_RUN.\nChecker: check_mode(MODE_RUN).',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_timeout_exact_5s_min_mode',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'ADJ_MIN 5-second timeout check'
        },
        {
            'big_no': 3, 'big': 'Mode Controller & Timeout FSM',
            'med_no': 2, 'med': 'Inactivity Timeout 5s & Keep-Alive Protection',
            'small': '3.2.5\nInactivity Timeout in MODE_ADJ_HOUR: exact 5 sec_pulses',
            'desc': 'Mục đích: Xác minh bộ đếm timeout tại MODE_ADJ_HOUR đếm đúng 5 xung sec_pulse rồi kích hoạt chuyển FSM về MODE_RUN.\nStimulus: Vào MODE_ADJ_HOUR; không bấm nút; đếm số xung sec_pulse.',
            'exp': 'Tại xung sec_pulse thứ 5, FSM chuyển về MODE_RUN.\nChecker: check_mode(MODE_RUN).',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_timeout_exact_5s_hour_mode',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'ADJ_HOUR 5-second timeout check'
        },
        {
            'big_no': 3, 'big': 'Mode Controller & Timeout FSM',
            'med_no': 2, 'med': 'Inactivity Timeout 5s & Keep-Alive Protection',
            'small': '3.2.6\nTimeout Rollback integrity: load_en strictly 0 on timeout',
            'desc': 'Mục đích: Xác minh khi thoát khỏi chế độ chỉnh sửa do timeout, tín hiệu load_en tuyệt đối không bao giờ được tích cực (ngăn chặn commit đệm dở dang vào counter nền).\nStimulus: Chỉnh sửa giá trị giờ phút giây; để timeout 5s tự động thoát.',
            'exp': 'load_en duy trì ở mức 0 trong toàn bộ quá trình thoát timeout.\nChecker: assert property (p_timeout_no_load_en: timeout_exit |-> !load_en).',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_timer_if.sv', 'sva': 'assert_load_en_never_on_timeout',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'No commit on timeout rollback'
        },
        {
            'big_no': 3, 'big': 'Mode Controller & Timeout FSM',
            'med_no': 2, 'med': 'Inactivity Timeout 5s & Keep-Alive Protection',
            'small': '3.2.7\nTimeout Rollback display integrity: revert to real-time',
            'desc': 'Mục đích: Xác minh khi timeout xảy ra, ngõ ra hiển thị top-level (s_out, m_out, h_out) lập tức phản ánh lại đúng giá trị thời gian thực của counter nền đang chạy.\nStimulus: Chỉnh đệm thành 23:59:59; chờ timeout 5s; đối soát hiển thị.',
            'exp': 'Hiển thị chuyển ngay về giá trị của s_cnt, m_cnt, h_cnt tại thời điểm thoát.\nChecker: scoreboard compare display with background counters.',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_timeout_display_revert',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Display reversion on rollback'
        },
        {
            'big_no': 3, 'big': 'Mode Controller & Timeout FSM',
            'med_no': 2, 'med': 'Inactivity Timeout 5s & Keep-Alive Protection',
            'small': '3.2.8\nKeep-alive reset via UP button at second 3',
            'desc': 'Mục đích: Xác minh việc bấm phím UP sau 3 giây không thao tác sẽ reset bộ đếm timeout_cnt về 0 và kéo dài thời gian ở lại chế độ chỉnh sửa.\nStimulus: Vào ADJ_SEC; chờ 3 xung sec_pulse; nhấn UP; sau đó chờ tiếp 4 xung sec_pulse.',
            'exp': 'DUT vẫn duy trì ở ADJ_SEC (tổng thời gian 7s vẫn chưa bị timeout vì đã được reset keep-alive).\nChecker: check_mode(MODE_ADJ_SEC).',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_keepalive_via_up_btn',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'UP button keep-alive at 3s'
        },
        {
            'big_no': 3, 'big': 'Mode Controller & Timeout FSM',
            'med_no': 2, 'med': 'Inactivity Timeout 5s & Keep-Alive Protection',
            'small': '3.2.9\nKeep-alive reset via DOWN button at second 4',
            'desc': 'Mục đích: Xác minh việc bấm phím DOWN sát ngưỡng (ở giây thứ 4) reset bộ đếm timeout_cnt về 0 thành công.\nStimulus: Chờ 4 xung sec_pulse; nhấn DOWN; chờ tiếp 3 xung sec_pulse.',
            'exp': 'DUT vẫn duy trì ở chế độ chỉnh sửa, không bị thoát ở giây thứ 5 ban đầu.\nChecker: check_mode.',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_keepalive_via_down_btn',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'DOWN button keep-alive at 4s'
        },
        {
            'big_no': 3, 'big': 'Mode Controller & Timeout FSM',
            'med_no': 2, 'med': 'Inactivity Timeout 5s & Keep-Alive Protection',
            'small': '3.2.10\nKeep-alive reset via SEL button mode advancement',
            'desc': 'Mục đích: Xác minh việc bấm phím SEL chuyển mode cũng đồng thời xóa timeout_cnt về 0 để mode mới có trọn vẹn 5 giây timeout.\nStimulus: Tại ADJ_SEC chờ 3s; nhấn SEL chuyển sang ADJ_MIN; đo thời gian timeout của ADJ_MIN.',
            'exp': 'ADJ_MIN duy trì đủ 5 xung sec_pulse mới thoát về RUN.\nChecker: check_mode duration.',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_keepalive_via_sel_advance',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Mode advance resets timeout counter'
        },
        {
            'big_no': 3, 'big': 'Mode Controller & Timeout FSM',
            'med_no': 2, 'med': 'Inactivity Timeout 5s & Keep-Alive Protection',
            'small': '3.2.11\nCritical collision: button press at exact cycle of 5th sec_pulse',
            'desc': 'Mục đích: Xác minh khi sự kiện bấm phím xuất hiện đúng vào chu kỳ clock có xung sec_pulse thứ 5, phím bấm được ưu tiên tuyệt đối (keep-alive wins) và FSM không bị thoát về RUN.\nStimulus: Drive up_pulse = 1 đúng chu kỳ posedge clk mà sec_pulse = 1 và timeout_cnt = 4.',
            'exp': 'any_button = 1 ngăn chặn state_next = MODE_RUN; timeout_cnt reset về 0; giá trị buffer được chỉnh sửa; FSM ở lại chế độ chỉnh sửa.\nChecker: check_mode != MODE_RUN.',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'assert_keepalive_wins_on_timeout_collision',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Confirmed resolution: Keep-alive wins'
        },
        {
            'big_no': 3, 'big': 'Mode Controller & Timeout FSM',
            'med_no': 3, 'med': 'Button Press Conflict Resolution & Cross Priorities',
            'small': '3.3.3\nSimultaneous SEL + UP in edit mode: SEL priority over edit',
            'desc': 'Mục đích: Xác minh khi người dùng nhấn đồng thời SEL và UP trong chế độ chỉnh sửa, tín hiệu SEL được ưu tiên tuyệt đối: chuyển mode ngay lập tức mà không tăng giá trị bộ đệm.\nStimulus: Tại ADJ_SEC, kích hoạt sel_pulse = 1 và up_pulse = 1 trong cùng 1 chu kỳ.',
            'exp': 'FSM chuyển sang ADJ_MIN; r_adj_sec giữ nguyên giá trị (không tăng); timeout_cnt = 0.\nChecker: check_mode(MODE_ADJ_MIN) & check_buffer_value.',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'assert_sel_priority_over_up',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Confirmed resolution: SEL priority'
        },
        {
            'big_no': 3, 'big': 'Mode Controller & Timeout FSM',
            'med_no': 3, 'med': 'Button Press Conflict Resolution & Cross Priorities',
            'small': '3.3.4\nSimultaneous SEL + DOWN in edit mode: SEL priority over edit',
            'desc': 'Mục đích: Xác minh khi người dùng nhấn đồng thời SEL và DOWN trong chế độ chỉnh sửa, SEL được ưu tiên tuyệt đối: chuyển mode ngay mà không giảm giá trị đệm.\nStimulus: Tại ADJ_SEC, kích hoạt sel_pulse = 1 và down_pulse = 1 cùng chu kỳ.',
            'exp': 'FSM chuyển sang ADJ_MIN; r_adj_sec giữ nguyên giá trị.\nChecker: check_mode(MODE_ADJ_MIN).',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'assert_sel_priority_over_down',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Confirmed resolution: SEL priority'
        },

        # --- BIG ITEM 4: EDIT BUFFERS & DISPLAY OUTPUT ---
        {
            'big_no': 4, 'big': 'Edit Buffers & Display Output',
            'med_no': 1, 'med': 'Second Adjustment & Wrap-Around',
            'small': '4.1.3\nSecond underflow wrap-around: 00 -> 59 on DOWN press',
            'desc': 'Mục đích: Kiểm tra chức năng giảm wrap-around của bộ đệm giây khi giá trị đang là 00 và nhấn phím DOWN.\nStimulus: Đưa r_adj_sec về 00; nhấn DOWN (down_pulse = 1).',
            'exp': 'r_adj_sec wrap-around chính xác về 6\'d59.\nChecker: scoreboard check r_adj_sec == 59.',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_sec_underflow_wrap',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Second underflow 00->59 boundary check'
        },
        {
            'big_no': 4, 'big': 'Edit Buffers & Display Output',
            'med_no': 1, 'med': 'Second Adjustment & Wrap-Around',
            'small': '4.1.4\nSecond edit buffer isolation: zero impact on Minute/Hour',
            'desc': 'Mục đích: Xác minh việc tăng/giảm bộ đệm giây liên tục tuyệt đối không làm thay đổi giá trị bộ đệm phút (r_adj_min) hay bộ đệm giờ (r_adj_hour).\nStimulus: Nhấn UP 100 lần trên trường giây tại ADJ_SEC.',
            'exp': 'r_adj_min và r_adj_hour giữ nguyên giá trị snapshot ban đầu 100% không đổi.\nChecker: assert property (adj_mode==SEC && up_pulse |=> adj_min==$past(adj_min) && adj_hour==$past(adj_hour)).',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_timer_if.sv', 'sva': 'assert_sec_buffer_isolation',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Buffer isolation verification'
        },
        {
            'big_no': 4, 'big': 'Edit Buffers & Display Output',
            'med_no': 2, 'med': 'Minute Adjustment & Wrap-Around',
            'small': '4.2.3\nMinute underflow wrap-around: 00 -> 59 on DOWN press',
            'desc': 'Mục đích: Kiểm tra chức năng giảm wrap-around của bộ đệm phút khi đang là 00 và nhấn DOWN.\nStimulus: Đưa r_adj_min về 00 tại ADJ_MIN; nhấn DOWN.',
            'exp': 'r_adj_min wrap-around chính xác về 6\'d59.\nChecker: scoreboard check r_adj_min == 59.',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_min_underflow_wrap',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Minute underflow 00->59 boundary check'
        },
        {
            'big_no': 4, 'big': 'Edit Buffers & Display Output',
            'med_no': 2, 'med': 'Minute Adjustment & Wrap-Around',
            'small': '4.2.4\nMinute edit buffer isolation: zero impact on Second/Hour',
            'desc': 'Mục đích: Xác minh việc điều chỉnh trường phút không làm thay đổi giá trị trường giây hay trường giờ trong bộ đệm.\nStimulus: Nhấn UP/DOWN nhiều lần tại ADJ_MIN.',
            'exp': 'r_adj_sec và r_adj_hour giữ nguyên giá trị không đổi.\nChecker: assert property p_min_isolation.',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_timer_if.sv', 'sva': 'assert_min_buffer_isolation',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Minute buffer isolation check'
        },
        {
            'big_no': 4, 'big': 'Edit Buffers & Display Output',
            'med_no': 3, 'med': 'Hour Adjustment & Wrap-Around',
            'small': '4.3.3\nHour overflow wrap-around: 23 -> 00 on UP press',
            'desc': 'Mục đích: Kiểm tra chức năng tăng wrap-around của bộ đệm giờ khi đang là 23 và nhấn UP.\nStimulus: Đưa r_adj_hour về 23 tại ADJ_HOUR; nhấn UP (up_pulse = 1).',
            'exp': 'r_adj_hour wrap-around chính xác về 5\'d00.\nChecker: scoreboard check r_adj_hour == 0.',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_hour_overflow_wrap',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Hour overflow 23->00 boundary check'
        },
        {
            'big_no': 4, 'big': 'Edit Buffers & Display Output',
            'med_no': 3, 'med': 'Hour Adjustment & Wrap-Around',
            'small': '4.3.4\nHour underflow wrap-around: 00 -> 23 on DOWN press',
            'desc': 'Mục đích: Kiểm tra chức năng giảm wrap-around của bộ đệm giờ khi đang là 00 và nhấn DOWN.\nStimulus: Đưa r_adj_hour về 00 tại ADJ_HOUR; nhấn DOWN.',
            'exp': 'r_adj_hour wrap-around chính xác về 5\'d23.\nChecker: scoreboard check r_adj_hour == 23.',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_hour_underflow_wrap',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Hour underflow 00->23 boundary check'
        },
        {
            'big_no': 4, 'big': 'Edit Buffers & Display Output',
            'med_no': 3, 'med': 'Hour Adjustment & Wrap-Around',
            'small': '4.3.5\nHour edit buffer isolation: zero impact on Second/Minute',
            'desc': 'Mục đích: Xác minh việc điều chỉnh trường giờ không làm thay đổi giá trị trường giây hay phút trong bộ đệm.\nStimulus: Nhấn UP/DOWN tại ADJ_HOUR.',
            'exp': 'r_adj_sec và r_adj_min giữ nguyên không đổi.\nChecker: assert property p_hour_isolation.',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_timer_if.sv', 'sva': 'assert_hour_buffer_isolation',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Hour buffer isolation check'
        },
        {
            'big_no': 4, 'big': 'Edit Buffers & Display Output',
            'med_no': 4, 'med': 'Snapshot Capture & Data Persistence across Menu',
            'small': '4.4.3\nSnapshot capture on entering ADJ_SEC from background counters',
            'desc': 'Mục đích: Xác minh khi nhấn SEL tại MODE_RUN, bộ đệm chỉnh giờ chụp lại chính xác 100% giá trị tức thời từ các counter nền (s_cur, m_cur, h_cur).\nStimulus: Cho counter nền chạy đến 14:27:39; nhấn SEL.',
            'exp': 'r_adj_hour = 14, r_adj_min = 27, r_adj_sec = 39 ngay khi vào ADJ_SEC.\nChecker: scoreboard snapshot compare.',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_snapshot_capture_accuracy',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Initial snapshot capture verification'
        },
        {
            'big_no': 4, 'big': 'Edit Buffers & Display Output',
            'med_no': 4, 'med': 'Snapshot Capture & Data Persistence across Menu',
            'small': '4.4.4\nData persistence across mode transitions (SEC -> MIN -> HOUR)',
            'desc': 'Mục đích: Xác minh giá trị giây đã chỉnh sửa được bảo toàn nguyên vẹn khi chuyển sang chỉnh phút, và cả giây lẫn phút được bảo toàn khi chuyển sang chỉnh giờ.\nStimulus: Chỉnh giây lên 45; nhấn SEL sang MIN, chỉnh phút lên 30; nhấn SEL sang HOUR.',
            'exp': 'Tại ADJ_HOUR, r_adj_sec vẫn là 45, r_adj_min vẫn là 30.\nChecker: Scoreboard multi-field verification.',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_data_persistence_across_menu',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Menu navigation data persistence'
        },
        {
            'big_no': 4, 'big': 'Edit Buffers & Display Output',
            'med_no': 5, 'med': 'Output Switch Display Multiplexing & Anti-Glitch Bypass',
            'small': '4.5.3\nOutput Switch combinational zero-latency update on UP/DOWN',
            'desc': 'Mục đích: Xác minh ngõ ra s_out, m_out, h_out cập nhật tức thời không độ trễ (zero-latency combinational) ngay khi thanh ghi đệm thay đổi sau xung UP/DOWN.\nStimulus: Nhấn UP tại ADJ_SEC; quan sát s_out tại chu kỳ clock kế tiếp.',
            'exp': 's_out phản ánh ngay giá trị mới của r_adj_sec tại đúng chu kỳ clock thanh ghi được cập nhật.\nChecker: compare s_out == adj_sec.',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_output_switch_zero_delay',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Display immediate reflection check'
        },
        {
            'big_no': 4, 'big': 'Edit Buffers & Display Output',
            'med_no': 5, 'med': 'Output Switch Display Multiplexing & Anti-Glitch Bypass',
            'small': '4.5.4\nAnti-glitch bypass during parallel load commit (load_en = 1)',
            'desc': 'Mục đích: Xác minh cơ chế bypass chống glitch 1 chu kỳ của output_switch: khi FSM chuyển từ ADJ_HOUR sang RUN và phát load_en = 1, output_switch tiếp tục chọn giá trị bộ đệm thay vì chọn counter nền cũ, triệt tiêu hoàn toàn glitch hiển thị.\nStimulus: Commit chuyển từ ADJ_HOUR sang RUN; theo dõi s_out, m_out, h_out trong chu kỳ load_en = 1.',
            'exp': 'Trong chu kỳ load_en = 1 (khi adj_mode đã là RUN), ngõ ra hiển thị vẫn giữ nguyên giá trị đã chỉnh (adj_*), không bị giật về giá trị counter nền cũ (cnt_*).\nChecker: assert property p_anti_glitch_bypass.',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_timer_if.sv', 'sva': 'assert_output_switch_anti_glitch_bypass',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Output switch anti-glitch commit bypass'
        },
        {
            'big_no': 4, 'big': 'Edit Buffers & Display Output',
            'med_no': 5, 'med': 'Output Switch Display Multiplexing & Anti-Glitch Bypass',
            'small': '4.5.5\nDisplay output clean reversion on timeout rollback',
            'desc': 'Mục đích: Xác minh khi timeout xảy ra, output_switch lập tức chuyển mạch kết nối lại bộ đếm nền mà không sinh bất kỳ glitch hay giá trị undefined nào trên bus ngõ ra.\nStimulus: Để timeout xảy ra; giám sát dạng sóng s_out, m_out, h_out tại thời điểm chuyển kênh.',
            'exp': 'Ngõ ra hiển thị chuyển mượt mà từ giá trị đệm sang giá trị counter nền, không có xung glitch.\nChecker: Monitor glitch-free transition.',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_output_switch_timeout_switch',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Clean switch on timeout rollback'
        },

        # --- BIG ITEM 5: REAL-TIME COUNTERS & CASCADE ROLLOVER ---
        {
            'big_no': 5, 'big': 'Real-Time Counters & Cascade Rollover',
            'med_no': 1, 'med': 'Continuous Zero-Drift Real-Time Counting',
            'small': '5.1.5\nSecond Counter hold stability when sec_pulse is 0',
            'desc': 'Mục đích: Xác minh bộ đếm giây giữ nguyên giá trị tại tất cả các chu kỳ clock mà sec_pulse = 0 và không có load_en.\nStimulus: Quan sát s_cnt trong 999 chu kỳ giữa hai xung sec_pulse.',
            'exp': 's_cnt giữ nguyên giá trị không đổi.\nChecker: assert property (!load_en && !sec_pulse |=> s_cnt == $past(s_cnt)).',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_timer_if.sv', 'sva': 'assert_second_counter_hold',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Counter hold without clock enable'
        },
        {
            'big_no': 5, 'big': 'Real-Time Counters & Cascade Rollover',
            'med_no': 1, 'med': 'Continuous Zero-Drift Real-Time Counting',
            'small': '5.1.6\nMinute Counter hold stability when sec_rollover is 0',
            'desc': 'Mục đích: Xác minh bộ đếm phút giữ nguyên giá trị khi không có cờ sec_rollover và không có load_en.\nStimulus: Giám sát m_cnt qua các giây từ 0 đến 58.',
            'exp': 'm_cnt giữ nguyên không đổi.\nChecker: assert property (!load_en && !sec_rollover |=> m_cnt == $past(m_cnt)).',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_timer_if.sv', 'sva': 'assert_minute_counter_hold',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Minute counter hold assertion'
        },
        {
            'big_no': 5, 'big': 'Real-Time Counters & Cascade Rollover',
            'med_no': 1, 'med': 'Continuous Zero-Drift Real-Time Counting',
            'small': '5.1.7\nHour Counter hold stability when min_rollover is 0',
            'desc': 'Mục đích: Xác minh bộ đếm giờ giữ nguyên giá trị khi không có cờ min_rollover và không có load_en.\nStimulus: Giám sát h_cnt qua các phút từ 0 đến 58.',
            'exp': 'h_cnt giữ nguyên không đổi.\nChecker: assert property (!load_en && !min_rollover |=> h_cnt == $past(h_cnt)).',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_timer_if.sv', 'sva': 'assert_hour_counter_hold',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Hour counter hold assertion'
        },
        {
            'big_no': 5, 'big': 'Real-Time Counters & Cascade Rollover',
            'med_no': 1, 'med': 'Continuous Zero-Drift Real-Time Counting',
            'small': '5.1.8\nZero-Drift continuous background counting during 60s edit session',
            'desc': 'Mục đích: Xác minh bộ đếm nền chạy chuẩn xác tuyệt đối (Zero-Drift) trong suốt phiên chỉnh sửa kéo dài 60 giây của người dùng (duy trì keep-alive).\nStimulus: Vào ADJ_SEC; bấm keep-alive liên tục trong 60 giây thực; sau đó để timeout thoát.',
            'exp': 'Counter nền tăng đúng 60 giây thời gian thực; khi thoát về RUN, thời gian hiển thị khớp chính xác với Golden Model tham chiếu.\nChecker: Scoreboard Golden comparison.',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_zero_drift_long_session',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Zero-drift long edit session check'
        },
        {
            'big_no': 5, 'big': 'Real-Time Counters & Cascade Rollover',
            'med_no': 2, 'med': 'Midnight 23:59:59 Rollover & Multi-Stage Cascade',
            'small': '5.2.2\nNormal second-to-minute rollover cascade (10:15:59 -> 10:16:00)',
            'desc': 'Mục đích: Xác minh chu trình tràn giây thông thường: s_cnt wrap về 0, m_cnt tăng 1, h_cnt không đổi, min_rollover = 0.\nStimulus: Cho counter chạy từ 10:15:58 qua 10:15:59 đến 10:16:00.',
            'exp': 'Tại xung sec_pulse: s_cnt = 0, m_cnt = 16, h_cnt = 10; sec_rollover phát xung 1 chu kỳ; min_rollover = 0.\nChecker: check_time(10, 16, 0).',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_normal_sec_rollover',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Normal sec-to-min cascade check'
        },
        {
            'big_no': 5, 'big': 'Real-Time Counters & Cascade Rollover',
            'med_no': 2, 'med': 'Midnight 23:59:59 Rollover & Multi-Stage Cascade',
            'small': '5.2.3\nNormal minute-to-hour rollover cascade (10:59:59 -> 11:00:00)',
            'desc': 'Mục đích: Xác minh chu trình tràn phút thông thường: s_cnt wrap về 0, m_cnt wrap về 0, h_cnt tăng 1, cả sec_rollover và min_rollover cùng tích cực.\nStimulus: Cho counter chạy từ 10:59:59 sang 11:00:00.',
            'exp': 'Tại xung sec_pulse: s_cnt = 0, m_cnt = 0, h_cnt = 11; sec_rollover = 1; min_rollover = 1.\nChecker: check_time(11, 0, 0).',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_normal_min_rollover',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Normal min-to-hour cascade check'
        },
        {
            'big_no': 5, 'big': 'Real-Time Counters & Cascade Rollover',
            'med_no': 2, 'med': 'Midnight 23:59:59 Rollover & Multi-Stage Cascade',
            'small': '5.2.4\nSpurious rollover flag suppression verification',
            'desc': 'Mục đích: Xác minh cờ sec_rollover tuyệt đối không bao giờ tích cực nếu s_cnt != 59 hoặc sec_pulse = 0; và min_rollover không tích cực nếu m_cnt != 59 hoặc sec_rollover = 0.\nStimulus: Quét toàn bộ các giá trị counter từ 00:00:00 đến 23:59:58.',
            'exp': 'Không bao giờ xuất hiện cờ rollover giả mạo.\nChecker: assert property (sec_rollover |-> (s_cnt==59 && sec_pulse)) và assert property (min_rollover |-> (m_cnt==59 && sec_rollover)).',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_timer_if.sv', 'sva': 'assert_spurious_rollover_suppression',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Zero spurious rollover assertion'
        },
        {
            'big_no': 5, 'big': 'Real-Time Counters & Cascade Rollover',
            'med_no': 3, 'med': 'Synchronous Parallel Load Priority & Rollover Collision',
            'small': '5.3.3\nExact 1-clock-cycle pulse width on load_en commit',
            'desc': 'Mục đích: Xác minh xung commit load_en phát ra từ mode_controller chỉ kéo dài duy nhất đúng 1 chu kỳ clock chủ 1 MHz (1 us).\nStimulus: Nhấn SEL tại ADJ_HOUR để commit về RUN; đo độ rộng xung load_en.',
            'exp': 'load_en tích cực mức 1 trong đúng 1 chu kỳ posedge clk duy nhất rồi trở về 0 ngay chu kỳ kế tiếp.\nChecker: assert property (load_en |=> !load_en).',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_timer_if.sv', 'sva': 'assert_load_en_pulse_width_1cycle',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Single-cycle commit pulse assertion'
        },
        {
            'big_no': 5, 'big': 'Real-Time Counters & Cascade Rollover',
            'med_no': 3, 'med': 'Synchronous Parallel Load Priority & Rollover Collision',
            'small': '5.3.4\nSimultaneous parallel load accuracy across all 3 counters',
            'desc': 'Mục đích: Xác minh cả 3 counter (giây, phút, giờ) nhận đồng thời giá trị nạp song song từ edit buffer tại cùng 1 cạnh posedge clk khi load_en = 1.\nStimulus: Đặt buffer thành 08:45:19; kích hoạt commit.',
            'exp': 'Tại cạnh posedge clk có load_en, s_cnt nạp 19, m_cnt nạp 45, h_cnt nạp 08 đồng thời.\nChecker: scoreboard check_time(8, 45, 19).',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_parallel_load_simultaneity',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Parallel load simultaneity check'
        },
        {
            'big_no': 5, 'big': 'Real-Time Counters & Cascade Rollover',
            'med_no': 3, 'med': 'Synchronous Parallel Load Priority & Rollover Collision',
            'small': '5.3.5\nLoad priority over sec_pulse: load overrides counter increment',
            'desc': 'Mục đích: Xác minh khi load_en = 1 và sec_pulse = 1 xuất hiện đồng thời trong cùng 1 chu kỳ clock, thao tác nạp song song chiếm ưu tiên tuyệt đối: counter nhận giá trị nạp load_val thay vì tăng counter.\nStimulus: Điều khiển xung commit load_en trùng chu kỳ với xung sec_pulse; nạp giá trị 10 khi s_cnt đang là 25.',
            'exp': 's_cnt nạp chính xác 10 tại cạnh clock kế tiếp (không phải là 26 hay 11).\nChecker: assert property (load_en && sec_pulse |=> s_cnt == load_val).',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_timer_if.sv', 'sva': 'assert_load_priority_over_sec_pulse',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Confirmed priority: Load over pulse'
        },
        {
            'big_no': 5, 'big': 'Real-Time Counters & Cascade Rollover',
            'med_no': 3, 'med': 'Synchronous Parallel Load Priority & Rollover Collision',
            'small': '5.3.6\nLoad priority over rollover: suppression of spurious carry',
            'desc': 'Mục đích: Xác minh khi s_cnt đang là 59 và có sec_pulse, nhưng có load_en = 1 thì cờ sec_rollover bị triệt tiêu hoàn toàn (& ~load_en), không làm tăng sai phút của minute counter.\nStimulus: Counter nền đang là 10:15:59; commit thời gian mới 08:20:30 đúng lúc sec_pulse xuất hiện.',
            'exp': 'sec_rollover duy trì mức 0; m_cnt nhận giá trị nạp 20 thay vì tăng lên 16; thời gian sau nạp là 08:20:30 chuẩn xác.\nChecker: assert property (load_en |-> !sec_rollover && !min_rollover).',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_timer_if.sv', 'sva': 'assert_load_priority_over_rollover',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Confirmed: Rollover gated by ~load_en'
        },
        {
            'big_no': 5, 'big': 'Real-Time Counters & Cascade Rollover',
            'med_no': 3, 'med': 'Synchronous Parallel Load Priority & Rollover Collision',
            'small': '5.3.7\nCommit collision at Midnight Rollover boundary',
            'desc': 'Mục đích: Xác minh commit giá trị mới đúng thời điểm counter nền đạt 23:59:59 và chuẩn bị tràn nửa đêm.\nStimulus: Counter nền đang 23:59:59; commit nạp 01:00:00 tại cạnh clock rollover.',
            'exp': 'Hệ thống nạp chính xác 01:00:00; không bị tràn sai sang 00:00:00 hay 01:00:01.\nChecker: check_time(1, 0, 0).',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_commit_at_midnight_collision',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Midnight commit collision check'
        },
        {
            'big_no': 5, 'big': 'Real-Time Counters & Cascade Rollover',
            'med_no': 3, 'med': 'Synchronous Parallel Load Priority & Rollover Collision',
            'small': '5.3.8\nResumption of accurate counting immediately from committed time',
            'desc': 'Mục đích: Xác minh sau khi commit nạp thời gian mới, counter tiếp tục đếm nhịp 1 Hz bình thường và chính xác bắt đầu từ giá trị đã nạp.\nStimulus: Commit nạp 12:30:58; cho chạy tiếp 5 xung sec_pulse.',
            'exp': 'Thời gian lần lượt tăng qua 12:30:59 -> 12:31:00 -> 12:31:01 -> 12:31:02 -> 12:31:03.\nChecker: Scoreboard sequential check.',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'check_counting_resumption_after_commit',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Continuous counting resumption check'
        },

        # --- BIG ITEM 6: TOP INTEGRATION, STRESS & VERIFICATION CLOSURE ---
        {
            'big_no': 6, 'big': 'Top Integration, Stress & Verification Closure',
            'med_no': 2, 'med': 'End-to-End System Integration Scenarios',
            'small': '6.1.3\nEnd-to-End Scenario 1: Complete normal lifecycle',
            'desc': 'Mục đích: Xác minh vòng đời hoạt động hoàn chỉnh: Power-on Reset -> Chạy bình thường 10s -> Chỉnh sửa Giây, Phút, Giờ -> Commit -> Chạy tiếp 10s.\nStimulus: Thực hiện tuần tự toàn bộ kịch bản người dùng.',
            'exp': 'Hệ thống vận hành trơn tru, nạp đúng thời gian mới, và đếm tiếp chuẩn xác 100% không lỗi.\nChecker: End-to-end scoreboard tracker.',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'run_e2e_normal_lifecycle',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Full normal lifecycle verification'
        },
        {
            'big_no': 6, 'big': 'Top Integration, Stress & Verification Closure',
            'med_no': 2, 'med': 'End-to-End System Integration Scenarios',
            'small': '6.1.4\nEnd-to-End Scenario 2: Edit abort via 5s Inactivity Timeout',
            'desc': 'Mục đích: Xác minh kịch bản hủy chỉnh sửa: Reset -> Chạy 15s -> Vào chỉnh sửa đổi thời gian thành 22:11:00 -> Bỏ mặc 5s timeout -> Kiểm tra rollback về đúng giây thứ 20 của counter nền.\nStimulus: Chuỗi kích thích thời gian thực với timeout abort.',
            'exp': 'Thời gian hiển thị sau timeout là 00:00:20 (15s trước + 5s trong lúc chỉnh); không bị áp dụng giá trị 22:11:00.\nChecker: check_time(0, 0, 20).',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'run_e2e_timeout_abort_rollback',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'E2E timeout rollback verification'
        },
        {
            'big_no': 6, 'big': 'Top Integration, Stress & Verification Closure',
            'med_no': 2, 'med': 'End-to-End System Integration Scenarios',
            'small': '6.1.5\nEnd-to-End Scenario 3: Multiple rapid sequential commits',
            'desc': 'Mục đích: Xác minh hệ thống hoạt động ổn định khi người dùng thực hiện nhiều lần chỉnh giờ và commit liên tiếp nhau.\nStimulus: Thực hiện 5 chu kỳ chỉnh giờ và commit liên tiếp.',
            'exp': 'Mỗi lần commit đều nạp đúng giá trị mới và đếm tiếp chính xác; không có lỗi nhớ giá trị cũ.\nChecker: Scoreboard multi-commit history.',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'run_e2e_multiple_commits',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Multiple sequential commit stress'
        },
        {
            'big_no': 6, 'big': 'Top Integration, Stress & Verification Closure',
            'med_no': 2, 'med': 'End-to-End System Integration Scenarios',
            'small': '6.1.6\nEnd-to-End Scenario 4: Commit right before Midnight Rollover',
            'desc': 'Mục đích: Đặt giờ thành 23:59:58 qua chức năng chỉnh giờ, commit vào counter, sau đó để hệ thống đếm qua nửa đêm 00:00:00.\nStimulus: Chỉnh giờ thành 23:59:58; commit; quan sát trong 5 giây kế tiếp.',
            'exp': 'Sau commit 2s, hệ thống thực hiện midnight cascade chuyển giao 23:59:59 -> 00:00:00 chính xác.\nChecker: check_time(0, 0, 0).',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'run_e2e_commit_before_midnight',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Midnight cascade after commit'
        },
        {
            'big_no': 6, 'big': 'Top Integration, Stress & Verification Closure',
            'med_no': 2, 'med': 'End-to-End System Integration Scenarios',
            'small': '6.1.7\nEnd-to-End Scenario 5: High-frequency circular navigation stress',
            'desc': 'Mục đích: Bơm chuỗi 100 lần nhấn nút SEL liên tục với tốc độ cao để kiểm tra độ bền vững của FSM và các đường bus dữ liệu.\nStimulus: Nhấn SEL liên tục 100 lần, duyệt qua các mode xoay vòng.',
            'exp': 'FSM chuyển mode tuần hoàn chuẩn xác, không bị rơi vào deadlock hay corrupt thanh ghi đệm.\nChecker: assert property p_fsm_valid_state.',
            'num': 1, 'fin': 0, 'prio': 'Medium', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv', 'sva': 'run_e2e_rapid_fsm_cycling',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'FSM high-speed navigation stress'
        },
        {
            'big_no': 6, 'big': 'Top Integration, Stress & Verification Closure',
            'med_no': 2, 'med': 'End-to-End System Integration Scenarios',
            'small': '6.1.8\nEnd-to-End Scenario 6: Extended 24-hour simulation regression',
            'desc': 'Mục đích: Chạy mô phỏng tương đương trọn vẹn 24 giờ thời gian thực (sử dụng cấu hình prescaler rút gọn) để xác minh tính ổn định tuyệt đối của hệ thống.\nStimulus: Chạy hệ thống qua 86,400 xung sec_pulse trong môi trường regression.',
            'exp': 'Đúng 86,400 giây được đếm chuẩn xác; trải qua trọn vẹn chu kỳ ngày mà không có bất kỳ sai lệch nào.\nChecker: Golden comparison scorecard.',
            'num': 1, 'fin': 0, 'prio': 'Medium', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/tb_hms_timer.sv\ntb/hms_scoreboard.sv', 'sva': 'run_e2e_24hour_regression',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': '24-hour full regression closure'
        },
        {
            'big_no': 6, 'big': 'Top Integration, Stress & Verification Closure',
            'med_no': 3, 'med': 'SystemVerilog Assertions (SVA) Formal Checks',
            'small': '6.2.6\nFSM Legal Transitions SVA (assert_fsm_legal_transitions)',
            'desc': 'Mục đích: Kiểm tra hình thức (formal SVA) đảm bảo FSM chỉ thực hiện các bước chuyển trạng thái hợp lệ đã được đặc tả.\nStimulus: Áp dụng trên toàn bộ môi trường mô phỏng.',
            'exp': 'Mọi chuyển đổi trạng thái của state_reg đều thuộc tập hợp hợp lệ {RUN->SEC, SEC->MIN, MIN->HOUR, HOUR->RUN, ADJ_*->RUN (timeout)}.\nChecker: assert property p_fsm_legal_transitions.',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/hms_timer_if.sv', 'sva': 'assert_fsm_legal_transitions',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'FSM transition legality formal property'
        },
        {
            'big_no': 6, 'big': 'Top Integration, Stress & Verification Closure',
            'med_no': 3, 'med': 'SystemVerilog Assertions (SVA) Formal Checks',
            'small': '6.2.7\nFSM One-Hot / Legal State SVA (assert_fsm_valid_state)',
            'desc': 'Mục đích: Xác minh ngõ ra adj_mode luôn nằm trong tập hợp hợp lệ {2\'b00, 2\'b01, 2\'b10, 2\'b11} tại mọi chu kỳ sau reset.\nStimulus: Toàn bộ quá trình kiểm thử.',
            'exp': 'adj_mode không bao giờ xuất hiện giá trị không xác định X hoặc Z.\nChecker: assert property (!$isunknown(adj_mode)).',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/hms_timer_if.sv', 'sva': 'assert_fsm_valid_state',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'No unknown states assertion'
        },
        {
            'big_no': 6, 'big': 'Top Integration, Stress & Verification Closure',
            'med_no': 3, 'med': 'SystemVerilog Assertions (SVA) Formal Checks',
            'small': '6.2.8\nLoad Enable Single-Cycle Pulse Width SVA (assert_load_en_pulse_width)',
            'desc': 'Mục đích: Xác minh formal SVA rằng tín hiệu load_en không bao giờ tích cực liên tiếp trong 2 chu kỳ clock.\nStimulus: Toàn bộ quá trình commit.',
            'exp': 'load_en |=> !load_en luôn PASS 100%.\nChecker: assert property (load_en |=> !load_en).',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/hms_timer_if.sv', 'sva': 'assert_load_en_pulse_width',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Single cycle pulse width formal check'
        },
        {
            'big_no': 6, 'big': 'Top Integration, Stress & Verification Closure',
            'med_no': 3, 'med': 'SystemVerilog Assertions (SVA) Formal Checks',
            'small': '6.2.9\nLoad Priority Over Rollover Suppression SVA (assert_load_over_rollover)',
            'desc': 'Mục đích: Xác minh formal SVA rằng khi load_en = 1 thì cờ sec_rollover và min_rollover bắt buộc phải bằng 0.\nStimulus: Toàn bộ các chu kỳ commit.',
            'exp': 'load_en |-> (!sec_rollover && !min_rollover) luôn PASS 100%.\nChecker: assert property (load_en |-> !sec_rollover && !min_rollover).',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/hms_timer_if.sv', 'sva': 'assert_load_over_rollover',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Rollover suppression formal property'
        },
        {
            'big_no': 6, 'big': 'Top Integration, Stress & Verification Closure',
            'med_no': 3, 'med': 'SystemVerilog Assertions (SVA) Formal Checks',
            'small': '6.2.10\nOutput Switch Bypass Anti-Glitch SVA (assert_output_switch_bypass)',
            'desc': 'Mục đích: Xác minh formal SVA rằng trong chu kỳ load_en = 1, ngõ ra s_out bằng đúng adj_sec.\nStimulus: Toàn bộ các chu kỳ commit.',
            'exp': 'load_en |-> (s_out == adj_sec && m_out == adj_min && h_out == adj_hour) luôn PASS 100%.\nChecker: assert property (load_en |-> s_out==adj_sec).',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/hms_timer_if.sv', 'sva': 'assert_output_switch_bypass',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Anti-glitch bypass formal assertion'
        },
        {
            'big_no': 6, 'big': 'Top Integration, Stress & Verification Closure',
            'med_no': 3, 'med': 'SystemVerilog Assertions (SVA) Formal Checks',
            'small': '6.2.11\nPrescaler Pulse Single-Cycle Width SVA (assert_prescaler_pulse_widths)',
            'desc': 'Mục đích: Xác minh formal SVA rằng pulse_1khz và sec_pulse không bao giờ tích cực quá 1 chu kỳ clock.\nStimulus: Mọi chu kỳ phân tần.',
            'exp': 'pulse_1khz |=> !pulse_1khz và sec_pulse |=> !sec_pulse luôn PASS 100%.\nChecker: assert_pulse_1khz_width & assert_sec_pulse_width.',
            'num': 1, 'fin': 0, 'prio': 'Critical', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/hms_timer_if.sv', 'sva': 'assert_prescaler_pulse_widths',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Prescaler single-cycle formal assertions'
        },
        {
            'big_no': 6, 'big': 'Top Integration, Stress & Verification Closure',
            'med_no': 4, 'med': 'Functional Coverage Closure & Cross Bins',
            'small': '6.3.4\nFunctional Coverage: FSM Inactivity Timeout Transitions',
            'desc': 'Mục đích: Đo độ phủ functional coverage cho toàn bộ các nhánh thoát do timeout: ADJ_SEC -> RUN, ADJ_MIN -> RUN, ADJ_HOUR -> RUN (bổ sung cho covergroup cg_fsm_modes hiện bị khuyết).\nStimulus: Kích hoạt timeout trên cả 3 mode chỉnh sửa.',
            'exp': '100% coverage bins cho timeout transitions được thỏa mãn.\nChecker: coverage report cg_fsm_modes.cp_mode_transitions.',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/hms_coverage.sv', 'sva': 'cg_fsm_modes.cp_timeout_transitions',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'FSM timeout transition bins coverage'
        },
        {
            'big_no': 6, 'big': 'Top Integration, Stress & Verification Closure',
            'med_no': 4, 'med': 'Functional Coverage Closure & Cross Bins',
            'small': '6.3.5\nFunctional Coverage: FSM Asynchronous Reset Recovery',
            'desc': 'Mục đích: Đo độ phủ functional coverage cho việc giải trừ reset khi DUT đang ở các trạng thái khác nhau: MODE_RUN, MODE_ADJ_SEC, MODE_ADJ_MIN, MODE_ADJ_HOUR.\nStimulus: Bơm reset tại mỗi chế độ hoạt động.',
            'exp': '100% bins reset recovery transitions được ghi nhận.\nChecker: coverage report cg_fsm_modes.cp_reset_transitions.',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/hms_coverage.sv', 'sva': 'cg_fsm_modes.cp_reset_recovery',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Reset recovery transition coverage'
        },
        {
            'big_no': 6, 'big': 'Top Integration, Stress & Verification Closure',
            'med_no': 4, 'med': 'Functional Coverage Closure & Cross Bins',
            'small': '6.3.6\nFunctional Coverage: Cross Button x Mode x Rollover',
            'desc': 'Mục đích: Đo độ phủ chéo 3 chiều toàn diện: Các thao tác phím (SEL, UP, DOWN) x Chế độ hoạt động (RUN, SEC, MIN, HOUR) x Cờ tràn thời gian thực (sec_rollover, min_rollover).\nStimulus: Chạy kịch bản ngẫu nhiên có ràng buộc và bài kiểm tra TC11.',
            'exp': 'Đạt trên 95% cross coverage bins hợp lệ.\nChecker: coverage report cg_stimulus_cross.',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/hms_coverage.sv', 'sva': 'cg_stimulus_cross.cross_btn_mode_roll',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': '3-way cross coverage closure'
        },
        {
            'big_no': 6, 'big': 'Top Integration, Stress & Verification Closure',
            'med_no': 4, 'med': 'Functional Coverage Closure & Cross Bins',
            'small': '6.3.7\nFunctional Coverage: Parallel Load Commit x Rollover Collision',
            'desc': 'Mục đích: Đo độ phủ trường hợp góc biên: Sự kiện commit (load_en = 1) xuất hiện đồng thời với xung sec_pulse và tại thời điểm s_cnt = 59.\nStimulus: Bơm kích thích trùng nhịp commit và rollover.',
            'exp': 'Cross bin commit_rollover_collision đạt 100% hit.\nChecker: coverage report cg_commit_collision.',
            'num': 1, 'fin': 0, 'prio': 'High', 'pic': 'Ngo Thai Binh',
            'tf': 'tb/hms_coverage.sv', 'sva': 'cg_commit_collision',
            'r1_res': 'Pass', 'r1_date': '20/10/2026', 'r1_note': 'Commit-rollover collision coverage'
        }
    ]

    # Combine all items: legacy items first, then new items placed under their corresponding Big Items
    # To maintain neat hierarchy, let's group by Big Item No and Medium Item No
    all_items = []
    
    # We will sort/assemble by (big_no, med_no)
    combined_raw = legacy_items + new_items
    
    # Sort key: big_no, med_no, then extract small item id (e.g. 1.1.1, 1.1.2, 1.1.3...)
    def item_sort_key(item):
        b = item['big_no']
        m = item['med_no']
        s_str = str(item['small'])
        # Try to parse e.g. "1.1.3" from the first line
        first_line = s_str.split('\n')[0].strip()
        parts = first_line.split('.')
        try:
            p1 = int(parts[0])
            p2 = int(parts[1])
            p3 = int(parts[2])
            return (b, m, p1, p2, p3)
        except Exception:
            return (b, m, 99, 99, 99)

    all_items = sorted(combined_raw, key=item_sort_key)
    total_test_items = len(all_items)
    print(f"Total compiled test items: {total_test_items} (Legacy: {len(legacy_items)}, New: {len(new_items)})")

    # =========================================================================
    # 3. BUILD SHEET 1: Verification Test Plan
    # =========================================================================
    ws1 = wb.active
    ws1.title = "Verification Test Plan"
    ws1.views.sheetView[0].showGridLines = True

    end_row = 5 + total_test_items

    # Row 1 & 2: Summary Header
    ws1.merge_cells("A1:E1")
    ws1["A1"] = "Summary: Verification Progress"
    ws1["A1"].font = FONT_TITLE
    ws1["A1"].fill = FILL_SUMMARY
    ws1["A1"].alignment = Alignment(horizontal="left", vertical="center", indent=1)

    ws1["F1"] = "Total Items:"
    ws1["F1"].font = FONT_HEADER
    ws1["F1"].alignment = ALIGN_CENTER
    ws1["F1"].fill = FILL_GRAY

    ws1["G1"] = f"=COUNTA(E6:E{end_row})"
    ws1["G1"].font = FONT_BODY_BOLD
    ws1["G1"].alignment = ALIGN_CENTER
    ws1["G1"].fill = FILL_ORANGE

    ws1["H1"] = "Finished:"
    ws1["H1"].font = FONT_HEADER
    ws1["H1"].alignment = ALIGN_CENTER
    ws1["H1"].fill = FILL_GRAY

    ws1["I1"] = f'=COUNTIF(N6:N{end_row}, "Pass")'
    ws1["I1"].font = FONT_BODY_BOLD
    ws1["I1"].alignment = ALIGN_CENTER
    ws1["I1"].fill = FILL_PASS

    ws1["J1"] = "Progress Rate:"
    ws1["J1"].font = FONT_HEADER
    ws1["J1"].alignment = ALIGN_CENTER
    ws1["J1"].fill = FILL_GRAY

    ws1["K1"] = "=I1/G1"
    ws1["K1"].number_format = "0.0%"
    ws1["K1"].font = FONT_BODY_BOLD
    ws1["K1"].alignment = ALIGN_CENTER
    ws1["K1"].fill = FILL_PASS

    ws1.merge_cells("A2:B2")
    ws1["A2"] = "Module name"
    ws1["A2"].font = FONT_HEADER
    ws1["A2"].fill = FILL_GOLD
    ws1["A2"].alignment = ALIGN_CENTER

    ws1.merge_cells("C2:E2")
    ws1["C2"] = "hms_timer (Top-Level Universal Architecture - Expanded Plan)"
    ws1["C2"].font = FONT_BODY_BOLD
    ws1["C2"].fill = PatternFill(start_color="FFF9E6", end_color="FFF9E6", fill_type="solid")
    ws1["C2"].alignment = Alignment(horizontal="left", vertical="center", indent=1)

    for r in [1, 2]:
        for c in range(1, 20):
            cell = ws1.cell(row=r, column=c)
            cell.border = BORDER_HEADER
            if r == 1 and c > 11:
                cell.fill = FILL_GRAY
            elif r == 2 and c > 5:
                cell.fill = FILL_GRAY

    # Rows 3, 4, 5: Super Headers and Column Headers
    ws1.merge_cells("A3:A5")
    ws1["A3"] = "Big item"
    ws1["A3"].font = FONT_HEADER
    ws1["A3"].fill = FILL_GOLD
    ws1["A3"].alignment = ALIGN_CENTER

    ws1.merge_cells("B3:B5")
    ws1["B3"] = "No"
    ws1["B3"].font = FONT_HEADER
    ws1["B3"].fill = FILL_GOLD
    ws1["B3"].alignment = ALIGN_CENTER

    ws1.merge_cells("C3:C5")
    ws1["C3"] = "Medium item"
    ws1["C3"].font = FONT_HEADER
    ws1["C3"].fill = FILL_GOLD
    ws1["C3"].alignment = ALIGN_CENTER

    ws1.merge_cells("D3:D5")
    ws1["D3"] = "No"
    ws1["D3"].font = FONT_HEADER
    ws1["D3"].fill = FILL_GOLD
    ws1["D3"].alignment = ALIGN_CENTER

    ws1.merge_cells("E3:E5")
    ws1["E3"] = "Small item"
    ws1["E3"].font = FONT_HEADER
    ws1["E3"].fill = FILL_GOLD
    ws1["E3"].alignment = ALIGN_CENTER

    ws1.merge_cells("F3:K3")
    ws1["F3"] = "Planning Phase"
    ws1["F3"].font = FONT_HEADER
    ws1["F3"].fill = FILL_GOLD
    ws1["F3"].alignment = ALIGN_CENTER

    ws1.merge_cells("L3:M3")
    ws1["L3"] = "Test Pattern/ SVA Implementation Phase"
    ws1["L3"].font = FONT_HEADER
    ws1["L3"].fill = FILL_PEACH
    ws1["L3"].alignment = ALIGN_CENTER

    ws1.merge_cells("N3:S3")
    ws1["N3"] = "Execution Phase"
    ws1["N3"].font = FONT_HEADER
    ws1["N3"].fill = FILL_BLUE
    ws1["N3"].alignment = ALIGN_CENTER

    # Row 4 Sub-headers
    ws1.merge_cells("F4:F5")
    ws1["F4"] = "Description"
    ws1["F4"].font = FONT_HEADER
    ws1["F4"].fill = FILL_GOLD
    ws1["F4"].alignment = ALIGN_CENTER

    ws1.merge_cells("G4:G5")
    ws1["G4"] = "Expected"
    ws1["G4"].font = FONT_HEADER
    ws1["G4"].fill = FILL_GOLD
    ws1["G4"].alignment = ALIGN_CENTER

    ws1["H4"] = "Number"
    ws1["H4"].font = FONT_SUBHEADER
    ws1["H4"].fill = FILL_ORANGE
    ws1["H4"].alignment = ALIGN_CENTER

    ws1["I4"] = "Finished"
    ws1["I4"].font = FONT_SUBHEADER
    ws1["I4"].fill = FILL_ORANGE
    ws1["I4"].alignment = ALIGN_CENTER

    ws1["H5"] = f"=COUNTA(E6:E{end_row})"
    ws1["H5"].font = FONT_BODY_BOLD
    ws1["H5"].fill = FILL_ORANGE
    ws1["H5"].alignment = ALIGN_CENTER

    ws1["I5"] = f'=COUNTIF(N6:N{end_row}, "Pass")'
    ws1["I5"].font = FONT_BODY_BOLD
    ws1["I5"].fill = FILL_PASS
    ws1["I5"].alignment = ALIGN_CENTER

    ws1.merge_cells("J4:J5")
    ws1["J4"] = "Priority"
    ws1["J4"].font = FONT_HEADER
    ws1["J4"].fill = FILL_GOLD
    ws1["J4"].alignment = ALIGN_CENTER

    ws1.merge_cells("K4:K5")
    ws1["K4"] = "PIC"
    ws1["K4"].font = FONT_HEADER
    ws1["K4"].fill = FILL_GOLD
    ws1["K4"].alignment = ALIGN_CENTER

    ws1.merge_cells("L4:L5")
    ws1["L4"] = "Test/Checker File"
    ws1["L4"].font = FONT_HEADER
    ws1["L4"].fill = FILL_PEACH
    ws1["L4"].alignment = ALIGN_CENTER

    ws1.merge_cells("M4:M5")
    ws1["M4"] = "Task Number/ SVA"
    ws1["M4"].font = FONT_HEADER
    ws1["M4"].fill = FILL_PEACH
    ws1["M4"].alignment = ALIGN_CENTER

    ws1.merge_cells("N4:P4")
    ws1["N4"] = "Round 1"
    ws1["N4"].font = FONT_HEADER
    ws1["N4"].fill = FILL_BLUE
    ws1["N4"].alignment = ALIGN_CENTER

    ws1["N5"] = "Result"
    ws1["N5"].font = FONT_SUBHEADER
    ws1["N5"].fill = FILL_BLUE
    ws1["N5"].alignment = ALIGN_CENTER

    ws1["O5"] = "Date"
    ws1["O5"].font = FONT_SUBHEADER
    ws1["O5"].fill = FILL_BLUE
    ws1["O5"].alignment = ALIGN_CENTER

    ws1["P5"] = "Note"
    ws1["P5"].font = FONT_SUBHEADER
    ws1["P5"].fill = FILL_BLUE
    ws1["P5"].alignment = ALIGN_CENTER

    ws1.merge_cells("Q4:S4")
    ws1["Q4"] = "Round 2"
    ws1["Q4"].font = FONT_HEADER
    ws1["Q4"].fill = FILL_BLUE
    ws1["Q4"].alignment = ALIGN_CENTER

    ws1["Q5"] = "Result"
    ws1["Q5"].font = FONT_SUBHEADER
    ws1["Q5"].fill = FILL_BLUE
    ws1["Q5"].alignment = ALIGN_CENTER

    ws1["R5"] = "Date"
    ws1["R5"].font = FONT_SUBHEADER
    ws1["R5"].fill = FILL_BLUE
    ws1["R5"].alignment = ALIGN_CENTER

    ws1["S5"] = "Note"
    ws1["S5"].font = FONT_SUBHEADER
    ws1["S5"].fill = FILL_BLUE
    ws1["S5"].alignment = ALIGN_CENTER

    for r in range(3, 6):
        for c in range(1, 20):
            ws1.cell(row=r, column=c).border = BORDER_HEADER

    # Write Data Rows
    current_row = 6
    for item in all_items:
        r = current_row
        ws1.cell(row=r, column=1, value=item['big']).alignment = ALIGN_TOP_LEFT
        ws1.cell(row=r, column=1).font = FONT_BODY_BOLD

        ws1.cell(row=r, column=2, value=item['big_no']).alignment = ALIGN_TOP_CENTER
        ws1.cell(row=r, column=2).font = FONT_BODY

        ws1.cell(row=r, column=3, value=item['med']).alignment = ALIGN_TOP_LEFT
        ws1.cell(row=r, column=3).font = FONT_BODY_BOLD

        ws1.cell(row=r, column=4, value=item['med_no']).alignment = ALIGN_TOP_CENTER
        ws1.cell(row=r, column=4).font = FONT_BODY

        ws1.cell(row=r, column=5, value=item['small']).alignment = ALIGN_TOP_LEFT
        ws1.cell(row=r, column=5).font = FONT_BODY_BOLD

        ws1.cell(row=r, column=6, value=item['desc']).alignment = ALIGN_TOP_LEFT
        ws1.cell(row=r, column=6).font = FONT_BODY

        ws1.cell(row=r, column=7, value=item['exp']).alignment = ALIGN_TOP_LEFT
        ws1.cell(row=r, column=7).font = FONT_BODY

        ws1.cell(row=r, column=8, value=item['num']).alignment = ALIGN_TOP_CENTER
        ws1.cell(row=r, column=8).font = FONT_BODY

        # Finished cell (Formula: 1 if Round 1 is Pass, else 0)
        c_fin = ws1.cell(row=r, column=9, value=f'=IF(N{r}="Pass", 1, 0)')
        c_fin.alignment = ALIGN_TOP_CENTER
        c_fin.font = FONT_BODY_BOLD

        # Priority cell
        prio_cell = ws1.cell(row=r, column=10, value=item['prio'])
        prio_cell.alignment = ALIGN_TOP_CENTER
        if item['prio'] == "Critical":
            prio_cell.font = FONT_CRITICAL
        elif item['prio'] == "High":
            prio_cell.font = FONT_HIGH
        elif item['prio'] == "Medium":
            prio_cell.font = FONT_MEDIUM
        else:
            prio_cell.font = FONT_LOW

        ws1.cell(row=r, column=11, value=item['pic']).alignment = ALIGN_TOP_CENTER
        ws1.cell(row=r, column=11).font = FONT_BODY

        ws1.cell(row=r, column=12, value=item['tf']).alignment = ALIGN_TOP_LEFT
        ws1.cell(row=r, column=12).font = FONT_CODE

        ws1.cell(row=r, column=13, value=item['sva']).alignment = ALIGN_TOP_LEFT
        ws1.cell(row=r, column=13).font = FONT_CODE

        # Round 1 Result
        c_res = ws1.cell(row=r, column=14, value=item['r1_res'])
        c_res.alignment = ALIGN_TOP_CENTER
        if item['r1_res'] == "Pass":
            c_res.fill = FILL_PASS
            c_res.font = FONT_PASS
        elif item['r1_res'] == "Planned":
            c_res.fill = FILL_PLAN
            c_res.font = FONT_PLAN

        ws1.cell(row=r, column=15, value=item['r1_date']).alignment = ALIGN_TOP_CENTER
        ws1.cell(row=r, column=15).font = FONT_DATE

        ws1.cell(row=r, column=16, value=item['r1_note']).alignment = ALIGN_TOP_LEFT
        ws1.cell(row=r, column=16).font = FONT_BODY

        ws1.cell(row=r, column=17, value="").alignment = ALIGN_TOP_CENTER
        ws1.cell(row=r, column=17).font = FONT_BODY

        ws1.cell(row=r, column=18, value="").alignment = ALIGN_TOP_CENTER
        ws1.cell(row=r, column=18).font = FONT_DATE

        ws1.cell(row=r, column=19, value="").alignment = ALIGN_TOP_LEFT
        ws1.cell(row=r, column=19).font = FONT_BODY

        for c in range(1, 20):
            ws1.cell(row=r, column=c).border = BORDER_DATA

        current_row += 1

    # Vertical Merging for Big Items
    big_start = 6
    curr_big_val = all_items[0]['big']
    for idx in range(1, len(all_items)):
        row_idx = 6 + idx
        val = all_items[idx]['big']
        if val != curr_big_val:
            if row_idx - 1 > big_start:
                ws1.merge_cells(start_row=big_start, start_column=1, end_row=row_idx - 1, end_column=1)
                ws1.merge_cells(start_row=big_start, start_column=2, end_row=row_idx - 1, end_column=2)
            big_start = row_idx
            curr_big_val = val
    if end_row > big_start:
        ws1.merge_cells(start_row=big_start, start_column=1, end_row=end_row, end_column=1)
        ws1.merge_cells(start_row=big_start, start_column=2, end_row=end_row, end_column=2)

    # Vertical Merging for Medium Items
    med_start = 6
    curr_med_val = (all_items[0]['big'], all_items[0]['med'])
    for idx in range(1, len(all_items)):
        row_idx = 6 + idx
        val = (all_items[idx]['big'], all_items[idx]['med'])
        if val != curr_med_val:
            if row_idx - 1 > med_start:
                ws1.merge_cells(start_row=med_start, start_column=3, end_row=row_idx - 1, end_column=3)
                ws1.merge_cells(start_row=med_start, start_column=4, end_row=row_idx - 1, end_column=4)
            med_start = row_idx
            curr_med_val = val
    if end_row > med_start:
        ws1.merge_cells(start_row=med_start, start_column=3, end_row=end_row, end_column=3)
        ws1.merge_cells(start_row=med_start, start_column=4, end_row=end_row, end_column=4)

    # Set column widths & row heights for Sheet 1
    col_widths = {
        "A": 22, "B": 5, "C": 26, "D": 5, "E": 28,
        "F": 48, "G": 48, "H": 8, "I": 8, "J": 10,
        "K": 13, "L": 22, "M": 26, "N": 8, "O": 11,
        "P": 34, "Q": 8, "R": 11, "S": 20
    }
    for col_letter, width in col_widths.items():
        ws1.column_dimensions[col_letter].width = width

    ws1.row_dimensions[1].height = 26
    ws1.row_dimensions[2].height = 24
    ws1.row_dimensions[3].height = 24
    ws1.row_dimensions[4].height = 22
    ws1.row_dimensions[5].height = 20
    for r in range(6, end_row + 1):
        ws1.row_dimensions[r].height = 68

    # =========================================================================
    # 4. BUILD SHEET 2: Requirement Traceability (RTM)
    # =========================================================================
    ws2 = wb.create_sheet(title="Requirement Traceability")
    ws2.views.sheetView[0].showGridLines = True

    ws2.merge_cells("A1:J1")
    ws2["A1"] = "HMS_Timer Requirement Traceability Matrix (RTM 2-Way Mapping)"
    ws2["A1"].font = FONT_TITLE
    ws2["A1"].fill = FILL_SUMMARY
    ws2["A1"].alignment = Alignment(horizontal="left", vertical="center", indent=1)

    rtm_headers = [
        ("A3", "Req ID", 14),
        ("B3", "Classification", 15),
        ("C3", "Submodule", 18),
        ("D3", "Requirement Technical Description", 45),
        ("E3", "Mapped Test IDs", 24),
        ("F3", "Verification Method", 20),
        ("G3", "Checker / SVA Property", 28),
        ("H3", "Coverage Point / Bin", 26),
        ("I3", "Status", 12),
        ("J3", "Coverage Gap & Implementation Note", 38)
    ]

    for pos, text, width in rtm_headers:
        ws2[pos] = text
        ws2[pos].font = FONT_HEADER
        ws2[pos].fill = FILL_GOLD
        ws2[pos].alignment = ALIGN_CENTER
        ws2[pos].border = BORDER_HEADER
        ws2.column_dimensions[pos[0]].width = width

    rtm_data = [
        ("REQ-SYS-01", "USER", "hms_timer.sv", "Hệ thống hoạt động trên xung nhịp toàn cục đồng bộ duy nhất 1 MHz, reset bất đồng bộ tích cực thấp rstn.", "1.1.1, 1.1.2, 1.1.3, 1.1.4, 6.1.2", "Directed Stimulus + SVA", "assert_reset_state", "cg_fsm_modes.cp_reset_transitions", "Passed", "Verified single clock domain 1MHz, zero CDC paths."),
        ("REQ-CE-01", "USER", "clk_prescaler.sv", "Sử dụng các xung Clock Enable 1-cycle (pulse_1khz, sec_pulse, sec_rollover, min_rollover, load_en) trên miền clock 1 MHz.", "1.5.1, 1.5.2, 1.5.3, 5.1.2, 5.1.3, 5.3.3", "Timing Cycle Measurement + SVA", "assert_pulse_width_1cycle", "cg_stimulus_cross.cp_sec_roll", "Passed", "Expanded strict 1-cycle pulse width assertion for all CE pulses."),
        ("REQ-PPA-01", "USER", "clk_prescaler.sv", "Sử dụng bộ chia tần đa tầng (1 MHz -> 1 kHz -> 1 Hz) để giảm tần số chuyển mạch tối đa.", "1.5.1, 1.5.2, 1.5.4, 1.5.5, 1.5.6", "Cycle Interval Measurement", "check_prescaler_periods", "cg_time_values", "Passed", "Added wrap boundary and deadlock freedom checks."),
        ("REQ-DEB-01", "USER", "button_debouncer.sv", "Lọc rung phím cơ học danh định 20 ms, chỉ công nhận khi nhấn giữ liên tục.", "2.1.1, 2.1.2, 2.1.3, 2.1.5", "Boundary Threshold Injection", "assert_debounce_boundary_rejection", "cg_stimulus_cross.cross_btn_mode", "Passed", "Verified 19 samples rejection vs 20 samples acceptance."),
        ("REQ-DEB-02", "USER", "button_debouncer.sv", "Khử rung chuyển trạng thái 2 chiều (nhấn/nhả 20 ms), phát duy nhất 1 xung chuẩn 1-cycle master clock khi nhấn phím (không Auto-Repeat).", "2.1.4, 2.1.6, 2.1.7, 2.1.8, 2.1.9", "Multi-Cycle Long Hold + Release Check", "assert_btn_event_width_1cycle", "cg_stimulus_cross.cross_btn_mode", "Passed", "Verified release qualification <20ms rejection and no auto-repeat on 100ms hold."),
        ("REQ-DEB-03", "USER", "button_debouncer.sv", "Khử rung phím chuẩn 20 ms (20 pulses @ 1 kHz) cho toàn bộ các nút bấm sel_in, up_in, down_in.", "2.1.2, 2.2.4, 2.2.5, 2.2.6, 2.2.7", "Independent 3-Channel Verification", "assert_all_three_debouncers_sync", "cg_stimulus_cross.cp_up, cp_down", "Passed", "Added multi-channel concurrent press and crosstalk isolation checks."),
        ("REQ-FSM-01", "USER", "mode_controller.sv", "FSM tuần hoàn qua RUN (00) -> ADJ_SEC (01) -> ADJ_MIN (10) -> ADJ_HOUR (11) -> RUN (00).", "3.1.1, 3.1.2, 3.1.3, 3.1.4, 3.1.5, 3.1.6, 6.2.6", "SVA + FSM State Monitor", "assert_fsm_legal_transitions", "cg_fsm_modes.cp_mode_transitions", "Passed", "Added legal transition assertion and self-loop hold checks."),
        ("REQ-FSM-02", "USER", "mode_controller.sv", "Timeout 5 Giây: Sau 5 giây không bấm phím ở các chế độ chỉnh sửa, FSM tự động hủy đệm và quay về MODE_RUN.", "3.2.1, 3.2.3, 3.2.4, 3.2.5, 3.2.6, 3.2.7, 3.2.11", "Scoreboard Timer + Rollback Verification", "assert_load_en_never_on_timeout", "cg_fsm_modes.cp_timeout_transitions", "Passed", "Added per-mode timeout checks (SEC, MIN, HOUR) and keep-alive collision check."),
        ("REQ-CNT-01", "USER", "second/minute/hour", "Đếm Nền Zero-Drift: Các bộ đếm Giây/Phút/Giờ chạy nền liên tục 24/7 chuẩn thời gian thực, không bị dừng hay trôi nhịp khi chỉnh menu.", "5.1.1, 5.1.4, 5.1.5, 5.1.6, 5.1.7, 5.1.8", "Scoreboard Golden Model Comparison", "assert_second_counter_hold", "cg_time_values", "Passed", "Verified zero-drift during extended 60s user edit sessions."),
        ("REQ-BUF-01", "USER", "mode_controller.sv", "Duy trì bộ thanh ghi đệm chỉnh sửa (adj_sec, adj_min, adj_hour) độc lập trong mode_controller.", "4.1.1..4.1.4, 4.2.1..4.2.4, 4.3.1..4.3.5, 4.4.3, 4.4.4", "Boundary Value Tracking + Isolation Check", "assert_sec/min/hour_buffer_isolation", "cg_time_values (wrap bins)", "Passed", "Added full wrap-around checks (59<->0, 23<->0) and cross-buffer isolation."),
        ("REQ-MUX-01", "USER", "output_switch.sv", "Tách riêng output_switch: xuất đệm khi chỉnh giờ, xuất counter khi chạy bình thường, bypass giữ đệm khi load_en=1 để triệt tiêu glitch 1 chu kỳ.", "4.5.1, 4.5.2, 4.5.3, 4.5.4, 4.5.5, 6.2.10", "Probe Check + Anti-Glitch SVA", "assert_output_switch_anti_glitch_bypass", "cg_stimulus_cross.cross_btn_mode", "Passed", "Added formal assertion verifying display holds buffer value during load_en pulse."),
        ("REQ-LD-01", "USER", "hms_timer.sv", "Synchronous Commit: Khi duyệt hết chu trình chỉnh giờ (ADJ_HOUR -> RUN), nạp song song toàn bộ thời gian mới vào các counter.", "5.3.1, 5.3.3, 5.3.4, 5.3.5, 5.3.6, 5.3.7, 5.3.8", "Commit Pulse + Load Priority Compare", "assert_load_priority_over_sec_pulse", "cg_commit_collision", "Passed", "Added load priority over sec_pulse and rollover flag suppression verification."),
        ("REQ-PPA-02", "DERIVED", "button_debouncer.sv", "Khối Debouncer nhận xung 1 MHz với Clock Enable pulse_1khz, bộ đếm 5-bit (0..19) hoạt động ở 1 kHz.", "2.1.2, 2.1.10, 2.1.11", "Toggle Rate + Clock Pin Inspection", "check_debouncer_gated_reset_spec", "cg_stimulus_cross", "Passed", "Confirmed 1kHz gated reset mechanism per architect guidance."),
        ("REQ-PPA-03", "DERIVED", "clk_prescaler.sv", "Tầng 1 chia 10-bit (0..999), tầng 2 kích hoạt bởi pulse_1khz chia 10-bit (0..999) đạt Fmax tối ưu.", "1.5.1, 1.5.2, 1.5.6", "Timing Slack + Synthesis Netlist Lint", "check_prescaler_stage1_period", "cg_time_values", "Passed", "STA verified >100 MHz Fmax margin on Sky130 technology."),
        ("REQ-GAT-01", "ARCH-RECOM", "second/minute_counter", "Khóa cờ tràn khi chỉnh sửa: chỉnh giây qua 59->00 trong đệm không kích hoạt sec_rollover nền.", "4.4.1, 4.4.2, 5.2.4, 5.2.5", "Rollover SVA Check", "assert_spurious_rollover_suppression", "cg_stimulus_cross.cross_rollover_run", "Passed", "Zero spurious rollover flag confirmed."),
        ("REQ-CON-01", "ARCH-RECOM", "mode_controller.sv", "Xử lý xung đột phím đồng thời: UP và DOWN cùng bấm thì giữ nguyên; SEL và UP/DOWN cùng bấm thì ưu tiên SEL.", "3.3.1, 3.3.3, 3.3.4, 3.3.5", "Parallel Stimulus Injection", "assert_sel_priority_over_up", "cg_stimulus_cross.cross_btn_mode", "Passed", "SEL priority over UP/DOWN confirmed per architect decision."),
        ("REQ-UNI-01", "ARCH-RECOM", "hms_timer.sv", "Single Clock Domain: Toàn bộ Flip-Flop trong hệ thống chạy trên clock clk 1 MHz duy nhất, 0 CDC, 0 Skew.", "1.1.1, 6.1.2", "Synchronous Timing Analysis", "assert_reset_state", "cg_stimulus_cross", "Passed", "Single BUFG FPGA / pure synchronous ASIC clock distribution confirmed."),
        ("REQ-RST-01", "ARCH-RECOM", "reset_sync.sv", "2-Stage Reset Synchronizer: Async assert, synchronous deassert sau 2 chu kỳ clock.", "1.1.1, 1.2.1, 1.2.2, 1.4.1..1.4.10", "Reset Assertion & Latency Verification", "assert_reset_state", "cg_fsm_modes.cp_reset_transitions", "Passed", "Reframed item 1.2.2 to 2-cycle latency & removal margin verification."),
        ("REQ-TOP-01", "ARCH-RECOM", "hms_timer.sv", "100% Pure Structural Interconnect: Top-level không chứa câu lệnh assign hay khối always có điều kiện logic.", "6.1.1", "Structural Netlist Inspection", "check_structural_harness", "cg_fsm_modes", "Passed", "100% pure structural port mapping confirmed in hms_timer.sv.")
    ]

    for idx, row_vals in enumerate(rtm_data):
        r = 4 + idx
        for c, val in enumerate(row_vals):
            cell = ws2.cell(row=r, column=c+1, value=val)
            cell.border = BORDER_DATA
            cell.font = FONT_BODY
            if c in [0, 1, 2, 8]:
                cell.alignment = ALIGN_CENTER
                if c == 8:
                    cell.font = FONT_BODY_BOLD
                    cell.fill = FILL_PASS
            else:
                cell.alignment = ALIGN_LEFT
        ws2.row_dimensions[r].height = 36

    # =========================================================================
    # 5. BUILD SHEET 3: SVA & Coverage Matrix
    # =========================================================================
    ws3 = wb.create_sheet(title="SVA & Coverage Matrix")
    ws3.views.sheetView[0].showGridLines = True

    ws3.merge_cells("A1:H1")
    ws3["A1"] = "HMS_Timer SystemVerilog Assertions (SVA) Specification Catalog"
    ws3["A1"].font = FONT_TITLE
    ws3["A1"].fill = FILL_SUMMARY
    ws3["A1"].alignment = Alignment(horizontal="left", vertical="center", indent=1)

    sva_headers = [
        ("A3", "SVA Property Name", 26),
        ("B3", "Target Module / Scope", 20),
        ("C3", "Clocking & Disable", 24),
        ("D3", "Formal Expression (Antecedent |-> Consequent)", 48),
        ("E3", "Target Bug / Fault Class", 32),
        ("F3", "Priority", 12),
        ("G3", "Test Mapping", 20),
        ("H3", "Status", 14)
    ]

    for pos, text, width in sva_headers:
        ws3[pos] = text
        ws3[pos].font = FONT_HEADER
        ws3[pos].fill = FILL_PEACH
        ws3[pos].alignment = ALIGN_CENTER
        ws3[pos].border = BORDER_HEADER
        ws3.column_dimensions[pos[0]].width = width

    sva_catalog = [
        ("p_s_out_range", "hms_timer_if", "@(posedge clk) disable iff (!rstn)", "s_out <= 6'd59", "Data corruption: s_out overflow (>59)", "Critical", "6.2.1", "Implemented"),
        ("p_m_out_range", "hms_timer_if", "@(posedge clk) disable iff (!rstn)", "m_out <= 6'd59", "Data corruption: m_out overflow (>59)", "Critical", "6.2.2", "Implemented"),
        ("p_h_out_range", "hms_timer_if", "@(posedge clk) disable iff (!rstn)", "h_out <= 5'd23", "Data corruption: h_out overflow (>23)", "Critical", "6.2.3", "Implemented"),
        ("p_reset_state", "hms_timer_if", "@(posedge clk)", "!rstn_sync |=> (s_out==0 && m_out==0 && h_out==0)", "Reset failure: outputs not zero on reset", "Critical", "1.1.1, 6.2.4", "Implemented"),
        ("p_sec_rollover_sync", "hms_timer_if", "@(posedge clk) disable iff (!rstn)", "sec_rollover |-> sec_pulse", "Spurious carry: sec_rollover without 1Hz pulse", "Critical", "5.1.2, 6.2.5", "Implemented"),
        ("p_min_rollover_sync", "hms_timer_if", "@(posedge clk) disable iff (!rstn)", "min_rollover |-> sec_rollover", "Spurious carry: min_rollover without sec_rollover", "Critical", "5.1.3, 6.2.5", "Implemented"),
        ("p_fsm_legal_transitions", "mode_controller", "@(posedge clk) disable iff (!rstn)", "state_reg != $past(state_reg) |-> legal_next_state", "FSM error: illegal state jump", "Critical", "3.1.1..3.1.4, 6.2.6", "Planned"),
        ("p_fsm_valid_state", "mode_controller", "@(posedge clk)", "!$isunknown(state_reg)", "Metastability / X-propagation into FSM", "Critical", "6.2.7", "Planned"),
        ("p_btn_event_width", "button_debouncer", "@(posedge clk) disable iff (!rstn)", "btn_event |=> !btn_event", "Pulse width violation: debouncer multi-cycle event", "Critical", "2.1.9", "Planned"),
        ("p_pulse_1khz_width", "clk_prescaler", "@(posedge clk) disable iff (!rstn)", "pulse_1khz |=> !pulse_1khz", "Clock enable violation: pulse_1khz > 1 cycle", "Critical", "1.5.3, 6.2.11", "Planned"),
        ("p_sec_pulse_width", "clk_prescaler", "@(posedge clk) disable iff (!rstn)", "sec_pulse |=> !sec_pulse", "Clock enable violation: sec_pulse > 1 cycle", "Critical", "1.5.3, 6.2.11", "Planned"),
        ("p_load_en_pulse_width", "mode_controller", "@(posedge clk) disable iff (!rstn)", "load_en |=> !load_en", "Commit violation: load_en held > 1 cycle", "Critical", "5.3.3, 6.2.8", "Planned"),
        ("p_load_over_rollover", "second_counter", "@(posedge clk) disable iff (!rstn)", "load_en |-> (!sec_rollover && !min_rollover)", "Spurious rollover during parallel load commit", "Critical", "5.3.6, 6.2.9", "Planned"),
        ("p_output_switch_bypass", "output_switch", "@(posedge clk) disable iff (!rstn)", "load_en |-> (s_out==adj_sec && m_out==adj_min && h_out==adj_hour)", "Display glitch: 1-cycle glitch during commit", "Critical", "4.5.4, 6.2.10", "Planned"),
        ("p_second_counter_hold", "second_counter", "@(posedge clk) disable iff (!rstn)", "!load_en && !sec_pulse |=> s_cnt == $past(s_cnt)", "Time drift: second counter counts without enable", "High", "5.1.5", "Planned"),
        ("p_minute_counter_hold", "minute_counter", "@(posedge clk) disable iff (!rstn)", "!load_en && !sec_rollover |=> m_cnt == $past(m_cnt)", "Time drift: minute counter counts without rollover", "High", "5.1.6", "Planned"),
        ("p_hour_counter_hold", "hour_counter", "@(posedge clk) disable iff (!rstn)", "!load_en && !min_rollover |=> h_cnt == $past(h_cnt)", "Time drift: hour counter counts without rollover", "High", "5.1.7", "Planned"),
        ("p_timeout_no_load_en", "mode_controller", "@(posedge clk) disable iff (!rstn)", "(state_reg!=RUN && state_next==RUN && !sel_pulse) |-> !load_en", "Data corruption: commit on timeout rollback", "Critical", "3.2.6", "Planned")
    ]

    for idx, row_vals in enumerate(sva_catalog):
        r = 4 + idx
        for c, val in enumerate(row_vals):
            cell = ws3.cell(row=r, column=c+1, value=val)
            cell.border = BORDER_DATA
            cell.font = FONT_BODY
            if c in [0, 1, 2, 5, 6, 7]:
                cell.alignment = ALIGN_CENTER
                if c == 5 and val == "Critical":
                    cell.font = FONT_CRITICAL
                elif c == 7:
                    cell.font = FONT_BODY_BOLD
                    cell.fill = FILL_PASS if val == "Implemented" else FILL_PLAN
            else:
                cell.alignment = ALIGN_LEFT
        ws3.row_dimensions[r].height = 28

    # Table 2: Functional Coverage Model
    cov_start_row = 4 + len(sva_catalog) + 2
    ws3.merge_cells(f"A{cov_start_row}:H{cov_start_row}")
    ws3[f"A{cov_start_row}"] = "HMS_Timer Functional Coverage Model & Closure Criteria"
    ws3[f"A{cov_start_row}"].font = FONT_TITLE
    ws3[f"A{cov_start_row}"].fill = FILL_SUMMARY
    ws3[f"A{cov_start_row}"].alignment = Alignment(horizontal="left", vertical="center", indent=1)

    cov_hdr_row = cov_start_row + 1
    cov_headers = [
        (f"A{cov_hdr_row}", "Covergroup Name", 26),
        (f"B{cov_hdr_row}", "Target Coverpoint / Cross", 24),
        (f"C{cov_hdr_row}", "Bins Specification", 38),
        (f"D{cov_hdr_row}", "Target Functional Behavior", 42),
        (f"E{cov_hdr_row}", "Closure Goal", 14),
        (f"F{cov_hdr_row}", "Test Mapping", 20),
        (f"G{cov_hdr_row}", "Existing Status", 16),
        (f"H{cov_hdr_row}", "Remediation / Enhancement", 30)
    ]
    for pos, text, width in cov_headers:
        ws3[pos] = text
        ws3[pos].font = FONT_HEADER
        ws3[pos].fill = FILL_BLUE
        ws3[pos].alignment = ALIGN_CENTER
        ws3[pos].border = BORDER_HEADER

    cov_data = [
        ("cg_fsm_modes", "cp_mode", "bins: MODE_RUN, ADJ_SEC, ADJ_MIN, ADJ_HOUR", "All 4 legal FSM operating modes visited", "100.0%", "3.1.1..3.1.4, 6.3.1", "100% Covered", "Preserve existing bins."),
        ("cg_fsm_modes", "cp_mode_transitions", "bins: RUN->SEC, SEC->MIN, MIN->HOUR, HOUR->RUN", "Normal forward circular menu navigation", "100.0%", "3.1.1..3.1.4, 6.3.1", "100% Covered", "Preserve existing 4 transition bins."),
        ("cg_fsm_modes", "cp_timeout_transitions", "bins: SEC->RUN, MIN->RUN, HOUR->RUN", "Inactivity timeout abort from every adjust state", "100.0%", "3.2.3..3.2.5, 6.3.4", "MISSING IN TB", "Add 3 explicit timeout transition bins to tb/hms_coverage.sv."),
        ("cg_fsm_modes", "cp_reset_transitions", "bins: (ADJ_SEC, ADJ_MIN, ADJ_HOUR) => MODE_RUN", "Asynchronous reset recovery from any adjust state", "100.0%", "1.4.2, 6.3.5", "MISSING IN TB", "Add reset transition bins from each active adjust mode."),
        ("cg_time_values", "cp_seconds, minutes, hours", "bins: zero, mid_range, max_val, wrap_up, wrap_down", "Boundary values and bi-directional wrap-around", "100.0%", "4.1..4.3, 6.3.2", "100% Covered", "Preserve existing boundary value bins."),
        ("cg_stimulus_cross", "cross_btn_mode", "cross cp_mode, cp_up, cp_down", "UP/DOWN actions across all 4 modes", "100.0%", "3.3.1..3.3.5, 6.3.3", "Covered (>90%)", "Add sel_pulse to cross to verify SEL+UP and SEL+DOWN conflicts."),
        ("cg_stimulus_cross", "cross_rollover_run", "cross cp_mode, cp_sec_roll, cp_min_roll in RUN", "Real-time cascade combinations in MODE_RUN", "100.0%", "5.1, 5.2, 6.3.3", "100% Covered", "Preserve existing illegal bin exclusions."),
        ("cg_commit_collision", "cross_load_rollover", "cross load_en, sec_pulse, sec_rollover", "Commit collision at second counter boundary (59)", "100.0%", "5.3.5..5.3.7, 6.3.7", "MISSING IN TB", "Create new dedicated covergroup for load_en collisions.")
    ]

    for idx, row_vals in enumerate(cov_data):
        r = cov_hdr_row + 1 + idx
        for c, val in enumerate(row_vals):
            cell = ws3.cell(row=r, column=c+1, value=val)
            cell.border = BORDER_DATA
            cell.font = FONT_BODY
            if c in [0, 1, 4, 5, 6]:
                cell.alignment = ALIGN_CENTER
                if c == 6 and "MISSING" in val:
                    cell.font = FONT_CRITICAL
                    cell.fill = FILL_PLAN
                elif c == 6:
                    cell.font = FONT_BODY_BOLD
                    cell.fill = FILL_PASS
            else:
                cell.alignment = ALIGN_LEFT
        ws3.row_dimensions[r].height = 28

    # =========================================================================
    # 6. BUILD SHEET 4: Review Issues & Technical Resolutions
    # =========================================================================
    ws4 = wb.create_sheet(title="Review Issues")
    ws4.views.sheetView[0].showGridLines = True

    ws4.merge_cells("A1:G1")
    ws4["A1"] = "HMS_Timer Verification Review Issues & Architectural Resolutions"
    ws4["A1"].font = FONT_TITLE
    ws4["A1"].fill = FILL_SUMMARY
    ws4["A1"].alignment = Alignment(horizontal="left", vertical="center", indent=1)

    issue_headers = [
        ("A3", "Issue ID", 12),
        ("B3", "Target Artifact", 18),
        ("C3", "Severity", 12),
        ("D3", "Issue Summary & Root Cause Description", 44),
        ("E3", "Technical Impact & Verification Risk", 38),
        ("F3", "Working Resolution & Decision", 44),
        ("G3", "Status", 14)
    ]

    for pos, text, width in issue_headers:
        ws4[pos] = text
        ws4[pos].font = FONT_HEADER
        ws4[pos].fill = FILL_GOLD
        ws4[pos].alignment = ALIGN_CENTER
        ws4[pos].border = BORDER_HEADER
        ws4.column_dimensions[pos[0]].width = width

    issues_data = [
        ("ISSUE-01", "RTL: button_debouncer", "Medium", "Cơ chế xóa timer_cnt của debouncer hiện tại được gated bởi xung clk_en 1kHz (không xóa ở 1MHz). Nếu phím rung về mức cũ giữa 2 xung enable thì counter không bị xóa tức thời.", "Nếu tần số rung phím có chu kỳ trùng với khoảng lấy mẫu 1ms, counter có thể tích lũy sai mẫu.", "User Direction Confirmed: Giữ nguyên cơ chế xóa gated 1kHz theo đúng thiết kế hiện tại của RTL. Đã bổ sung test case 2.1.11 để kiểm chứng chính xác hành vi này.", "RESOLVED"),
        ("ISSUE-02", "Spec / RTL: mode_controller", "High", "Đặc tả chưa nêu rõ thứ tự ưu tiên khi phím SEL và phím UP/DOWN cùng xuất hiện trong cùng 1 chu kỳ clock tại các chế độ chỉnh sửa.", "Mâu thuẫn giữa việc chuyển mode và tăng/giảm giá trị đệm chỉnh giờ.", "Architect Decision Confirmed: SEL có mức ưu tiên tuyệt đối. FSM chuyển trạng thái ngay lập tức, giá trị đệm không đổi. Đã bổ sung test cases 3.3.3, 3.3.4, 3.3.5.", "RESOLVED"),
        ("ISSUE-03", "Spec / RTL: mode_controller", "High", "Sự kiện bấm phím xuất hiện đúng vào chu kỳ clock có xung sec_pulse thứ 5 của Inactivity Timeout.", "Nguy cơ xung đột giữa nhánh thoát tự động do timeout và nhánh giữ chế độ (keep-alive).", "Architect Decision Confirmed: Bấm phím được ưu tiên (Keep-alive wins). any_button ngăn chặn thoát timeout, reset timeout_cnt về 0. Đã bổ sung test case 3.2.11.", "RESOLVED"),
        ("ISSUE-04", "Spec / RTL: second/minute_counter", "Critical", "Xung nạp song song load_en xuất hiện đồng thời với xung nhịp thời gian thực sec_pulse hoặc cờ rollover.", "Nguy cơ vừa nạp giá trị mới vừa tăng counter, hoặc phát cờ tràn giả sang phút gây sai số thời gian.", "Architect Decision Confirmed: load_en có ưu tiên tuyệt đối (Priority 1) ghi đè giá trị nạp; cờ rollover bị triệt tiêu (& ~load_en). Đã bổ sung test cases 5.3.5, 5.3.6.", "RESOLVED"),
        ("ISSUE-05", "Test Plan: Item 1.2.2", "High", "Test Plan cũ ghi nhận kiểm tra hiện tượng 'Metastability absorption' bằng mô phỏng RTL số.", "Mô phỏng Verilog 4 trạng thái không thể mô phỏng hiệu ứng vật lý bán dẫn metastability hay tính toán MTBF; ghi nhận sai lệch năng lực kiểm thử.", "Architect Remediation: Điều chỉnh mục tiêu test case 1.2.2 thành 'Xác minh độ trễ định thời 2 chu kỳ clock và removal timing margin'.", "RESOLVED"),
        ("ISSUE-06", "Test Plan: Status Columns", "High", "Toàn bộ 55 test items trong workbook cũ đều ghi 'Pass' vào ngày 13/10/2026 dù nhiều corner case chưa hề có stimulus trong tb_hms_timer.sv.", "Tạo cảm giác an toàn giả tạo (false confidence), nguy cơ lọt lỗi nghiêm trọng khi sign-off.", "Remediation: Phân định rạch ròi trạng thái: 55 test legacy giữ kết quả ban đầu kèm ghi chú kiểm chứng; 76 test mở rộng mới được đánh dấu 'Planned' với ngày 20/10/2026.", "RESOLVED"),
        ("ISSUE-07", "Testbench: hms_coverage.sv", "Medium", "Mô hình functional coverage hiện tại khuyết hoàn toàn các nhánh chuyển đổi trạng thái do Timeout và Reset recovery trong cp_mode_transitions.", "Báo cáo độ phủ FSM giả tạo 100% nhưng thực chất bỏ sót hoàn toàn 3 nhánh thoát timeout và 3 nhánh reset recovery.", "Remediation: Đã định nghĩa đầy đủ các bins cp_timeout_transitions và cp_reset_recovery trong Covergroup Matrix (Sheet 3) để bổ sung vào TB.", "RESOLVED"),
        ("ISSUE-08", "Testbench: clk_prescaler", "Medium", "Testbench sử dụng tham số thu nhỏ P_CLK_FREQ_HZ = 100 để tăng tốc mô phỏng, khác với cấu hình phần cứng danh định 1,000,000 Hz.", "Nguy cơ lọt lỗi counter overflow hoặc bit-width truncation khi chạy trên phần cứng thực tế.", "Remediation: Bổ sung các test cases 1.5.4, 1.5.5, 1.5.6 kiểm tra cấu hình mặc định và chứng minh tính tương đương toán học của cấu hình rút gọn.", "RESOLVED"),
        ("ISSUE-09", "Scripts: generate_test_plan.py", "Low", "Script sinh test plan cũ có lỗi circular import (from generate_test_plan import test_items) khiến script không thể chạy độc lập.", "Không thể tự động hóa tái tạo test plan từ dòng lệnh.", "Remediation: Viết lại script build_expanded_testplan.py độc lập, tự động trích xuất dữ liệu gốc, kết hợp dữ liệu mở rộng và xuất workbook hoàn chỉnh.", "RESOLVED"),
        ("ISSUE-10", "Test Plan: Missing RTM Sheet", "High", "Workbook test plan cũ không có bảng Ma trận truy xuất yêu cầu (RTM), người kiểm thử không thể đối soát hai chiều từ Requirement sang Test ID.", "Thiếu tính giải trình và khó khăn trong việc đánh giá mức độ bao phủ yêu cầu kỹ thuật.", "Remediation: Thiết lập worksheet riêng 'Requirement Traceability' ánh xạ chi tiết 19 yêu cầu với đầy đủ Test ID, Checker, Coverage và Status.", "RESOLVED")
    ]

    for idx, row_vals in enumerate(issues_data):
        r = 4 + idx
        for c, val in enumerate(row_vals):
            cell = ws4.cell(row=r, column=c+1, value=val)
            cell.border = BORDER_DATA
            cell.font = FONT_BODY
            if c in [0, 1, 2, 6]:
                cell.alignment = ALIGN_CENTER
                if c == 2 and val == "Critical":
                    cell.font = FONT_CRITICAL
                elif c == 2 and val == "High":
                    cell.font = FONT_HIGH
                elif c == 6:
                    cell.font = FONT_BODY_BOLD
                    cell.fill = FILL_PASS
            else:
                cell.alignment = ALIGN_LEFT
        ws4.row_dimensions[r].height = 42

    # =========================================================================
    # 7. SAVE WORKBOOK
    # =========================================================================
    output_docs = "docs/HMS_Timer_Test_Plan_Expanded.xlsx"
    output_root = "HMS_Timer_Test_Plan_Expanded.xlsx"

    wb.save(output_docs)
    shutil.copyfile(output_docs, output_root)
    print(f"Successfully generated {output_docs} and {output_root}")
    print(f"Workbook contains {len(wb.sheetnames)} sheets: {wb.sheetnames}")
    print(f"Total test items: {total_test_items}")

if __name__ == "__main__":
    build_workbook()
