//==============================================================================
// File: tc_sec4_buffers_display.sv
// Description: Testcases for Section 4: Edit Buffers & Display Output Multiplexing (Items 4.1.1 - 4.5.5)
//              Each small item is implemented as an individual, self-contained testcase.
// Project: HMS_Timer
// Language: SystemVerilog
//==============================================================================

`ifndef TC_SEC4_BUFFERS_DISPLAY_SV
`define TC_SEC4_BUFFERS_DISPLAY_SV

// 4.1.1: Second increment (Up) & wrap 59 -> 00
task automatic run_tc_4_1_1(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("4.1.1", "Second increment (Up) & wrap 59 -> 00");
    drv.reset_dut(10);
    drv.pulse_sel(); // ADJ_SEC
    drv.pulse_down(); // 0 -> 59
    sb.check_time(0, 0, 59, "TC_4_1_1_AT_59");
    drv.pulse_up();   // 59 -> 0
    sb.check_time(0, 0, 0, "TC_4_1_1_WRAP_TO_ZERO");
    finish_test_footer("4.1.1", "Second increment (Up) & wrap 59 -> 00", errs, sb);
endtask

// 4.1.2: Second decrement (Down) & wrap 00 -> 59
task automatic run_tc_4_1_2(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("4.1.2", "Second decrement (Down) & wrap 00 -> 59");
    drv.reset_dut(10);
    drv.pulse_sel(); // ADJ_SEC
    drv.pulse_up();  // 0 -> 1
    drv.pulse_up();  // 1 -> 2
    sb.check_time(0, 0, 2, "TC_4_1_2_AT_2");
    drv.pulse_down(); // 2 -> 1
    sb.check_time(0, 0, 1, "TC_4_1_2_DOWN_1");
    drv.pulse_down(); // 1 -> 0
    sb.check_time(0, 0, 0, "TC_4_1_2_DOWN_0");
    drv.pulse_down(); // 0 -> 59
    sb.check_time(0, 0, 59, "TC_4_1_2_WRAP_59");
    finish_test_footer("4.1.2", "Second decrement (Down) & wrap 00 -> 59", errs, sb);
endtask

// 4.1.3: Second underflow wrap-around: 00 -> 59 on DOWN press
task automatic run_tc_4_1_3(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("4.1.3", "Second underflow wrap-around: 00 -> 59 on DOWN press");
    drv.reset_dut(10);
    drv.pulse_sel(); // ADJ_SEC
    sb.check_int(vif.adj_sec, 0, "adj_sec_start", "TC_4_1_3");
    drv.pulse_down(); // 0 -> 59
    sb.check_int(vif.adj_sec, 59, "adj_sec_underflow", "TC_4_1_3");
    finish_test_footer("4.1.3", "Second underflow wrap-around: 00 -> 59 on DOWN press", errs, sb);
endtask

// 4.1.4: Second edit buffer isolation: zero impact on Minute/Hour
task automatic run_tc_4_1_4(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("4.1.4", "Second edit buffer isolation: zero impact on Minute/Hour");
    drv.reset_dut(10);
    drv.pulse_sel(); // ADJ_SEC
    sb.check_buffer(0, 0, 0, "TC_4_1_4_INIT_BUFFER");
    repeat (10) drv.pulse_up();
    repeat (15) drv.pulse_down();
    sb.check_int(vif.adj_min, 0, "adj_min_isolated", "TC_4_1_4");
    sb.check_int(vif.adj_hour, 0, "adj_hour_isolated", "TC_4_1_4");
    finish_test_footer("4.1.4", "Second edit buffer isolation: zero impact on Minute/Hour", errs, sb);
endtask

// 4.2.1: Minute increment (Up) & wrap 59 -> 00
task automatic run_tc_4_2_1(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("4.2.1", "Minute increment (Up) & wrap 59 -> 00");
    drv.reset_dut(10);
    drv.pulse_sel(); // SEC
    drv.pulse_sel(); // MIN
    drv.pulse_down(); // 0 -> 59
    sb.check_time(0, 59, 0, "TC_4_2_1_AT_59");
    drv.pulse_up();   // 59 -> 0
    sb.check_time(0, 0, 0, "TC_4_2_1_WRAP_TO_ZERO");
    finish_test_footer("4.2.1", "Minute increment (Up) & wrap 59 -> 00", errs, sb);
endtask

// 4.2.2: Minute decrement (Down) & wrap 00 -> 59
task automatic run_tc_4_2_2(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("4.2.2", "Minute decrement (Down) & wrap 00 -> 59");
    drv.reset_dut(10);
    drv.pulse_sel(); // SEC
    drv.pulse_sel(); // MIN
    drv.pulse_up();  // 0 -> 1
    drv.pulse_up();  // 1 -> 2
    sb.check_time(0, 2, 0, "TC_4_2_2_AT_2");
    drv.pulse_down(); // 2 -> 1
    sb.check_time(0, 1, 0, "TC_4_2_2_DOWN_1");
    drv.pulse_down(); // 1 -> 0
    sb.check_time(0, 0, 0, "TC_4_2_2_DOWN_0");
    drv.pulse_down(); // 0 -> 59
    sb.check_time(0, 59, 0, "TC_4_2_2_WRAP_59");
    finish_test_footer("4.2.2", "Minute decrement (Down) & wrap 00 -> 59", errs, sb);
endtask

// 4.2.3: Minute underflow wrap-around: 00 -> 59 on DOWN press
task automatic run_tc_4_2_3(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("4.2.3", "Minute underflow wrap-around: 00 -> 59 on DOWN press");
    drv.reset_dut(10);
    drv.pulse_sel(); // SEC
    drv.pulse_sel(); // MIN
    sb.check_int(vif.adj_min, 0, "adj_min_start", "TC_4_2_3");
    drv.pulse_down(); // 0 -> 59
    sb.check_int(vif.adj_min, 59, "adj_min_underflow", "TC_4_2_3");
    finish_test_footer("4.2.3", "Minute underflow wrap-around: 00 -> 59 on DOWN press", errs, sb);
endtask

// 4.2.4: Minute edit buffer isolation: zero impact on Second/Hour
task automatic run_tc_4_2_4(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("4.2.4", "Minute edit buffer isolation: zero impact on Second/Hour");
    drv.reset_dut(10);
    drv.pulse_sel(); // SEC
    drv.pulse_sel(); // MIN
    repeat (10) drv.pulse_up();
    repeat (15) drv.pulse_down();
    sb.check_int(vif.adj_sec, 0, "adj_sec_isolated", "TC_4_2_4");
    sb.check_int(vif.adj_hour, 0, "adj_hour_isolated", "TC_4_2_4");
    finish_test_footer("4.2.4", "Minute edit buffer isolation: zero impact on Second/Hour", errs, sb);
endtask

// 4.3.1: Hour increment (Up) & wrap 23 -> 00
task automatic run_tc_4_3_1(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("4.3.1", "Hour increment (Up) & wrap 23 -> 00");
    drv.reset_dut(10);
    drv.pulse_sel(); // SEC
    drv.pulse_sel(); // MIN
    drv.pulse_sel(); // HOUR
    drv.pulse_down(); // 0 -> 23
    sb.check_time(23, 0, 0, "TC_4_3_1_AT_23");
    drv.pulse_up();   // 23 -> 0
    sb.check_time(0, 0, 0, "TC_4_3_1_WRAP_TO_ZERO");
    finish_test_footer("4.3.1", "Hour increment (Up) & wrap 23 -> 00", errs, sb);
endtask

// 4.3.2: Hour decrement (Down) & wrap 00 -> 23
task automatic run_tc_4_3_2(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("4.3.2", "Hour decrement (Down) & wrap 00 -> 23");
    drv.reset_dut(10);
    drv.pulse_sel(); // SEC
    drv.pulse_sel(); // MIN
    drv.pulse_sel(); // HOUR
    drv.pulse_up();  // 0 -> 1
    drv.pulse_up();  // 1 -> 2
    sb.check_time(2, 0, 0, "TC_4_3_2_AT_2");
    drv.pulse_down(); // 2 -> 1
    sb.check_time(1, 0, 0, "TC_4_3_2_DOWN_1");
    drv.pulse_down(); // 1 -> 0
    sb.check_time(0, 0, 0, "TC_4_3_2_DOWN_0");
    drv.pulse_down(); // 0 -> 23
    sb.check_time(23, 0, 0, "TC_4_3_2_WRAP_23");
    finish_test_footer("4.3.2", "Hour decrement (Down) & wrap 00 -> 23", errs, sb);
endtask

// 4.3.3: Hour overflow wrap-around: 23 -> 00 on UP press
task automatic run_tc_4_3_3(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("4.3.3", "Hour overflow wrap-around: 23 -> 00 on UP press");
    drv.reset_dut(10);
    drv.pulse_sel(); // SEC
    drv.pulse_sel(); // MIN
    drv.pulse_sel(); // HOUR
    drv.pulse_down(); // 23
    sb.check_int(vif.adj_hour, 23, "adj_hour_at_23", "TC_4_3_3");
    drv.pulse_up();   // 23 -> 0
    sb.check_int(vif.adj_hour, 0, "adj_hour_wrapped_to_0", "TC_4_3_3");
    finish_test_footer("4.3.3", "Hour overflow wrap-around: 23 -> 00 on UP press", errs, sb);
endtask

// 4.3.4: Hour underflow wrap-around: 00 -> 23 on DOWN press
task automatic run_tc_4_3_4(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("4.3.4", "Hour underflow wrap-around: 00 -> 23 on DOWN press");
    drv.reset_dut(10);
    drv.pulse_sel(); // SEC
    drv.pulse_sel(); // MIN
    drv.pulse_sel(); // HOUR
    sb.check_int(vif.adj_hour, 0, "adj_hour_at_0", "TC_4_3_4");
    drv.pulse_down(); // 0 -> 23
    sb.check_int(vif.adj_hour, 23, "adj_hour_wrapped_to_23", "TC_4_3_4");
    finish_test_footer("4.3.4", "Hour underflow wrap-around: 00 -> 23 on DOWN press", errs, sb);
endtask

// 4.3.5: Hour edit buffer isolation: zero impact on Second/Minute
task automatic run_tc_4_3_5(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("4.3.5", "Hour edit buffer isolation: zero impact on Second/Minute");
    drv.reset_dut(10);
    drv.pulse_sel(); // SEC
    drv.pulse_sel(); // MIN
    drv.pulse_sel(); // HOUR
    repeat (10) drv.pulse_up();
    repeat (15) drv.pulse_down();
    sb.check_int(vif.adj_sec, 0, "adj_sec_isolated", "TC_4_3_5");
    sb.check_int(vif.adj_min, 0, "adj_min_isolated", "TC_4_3_5");
    finish_test_footer("4.3.5", "Hour edit buffer isolation: zero impact on Second/Minute", errs, sb);
endtask

// 4.4.1: Second wrap does not cascade to Minute buffer
task automatic run_tc_4_4_1(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("4.4.1", "Second wrap does not cascade to Minute buffer");
    drv.reset_dut(10);
    drv.pulse_sel(); // ADJ_SEC
    drv.pulse_down(); // 0 -> 59
    sb.check_time(0, 0, 59, "TC_4_4_1_SEC_59");
    drv.pulse_up();   // 59 -> 0
    sb.check_time(0, 0, 0, "TC_4_4_1_SEC_WRAPPED_0");
    sb.check_int(vif.adj_min, 0, "adj_min_not_incremented", "TC_4_4_1");
    finish_test_footer("4.4.1", "Second wrap does not cascade to Minute buffer", errs, sb);
endtask

// 4.4.2: Minute wrap does not cascade to Hour buffer
task automatic run_tc_4_4_2(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("4.4.2", "Minute wrap does not cascade to Hour buffer");
    drv.reset_dut(10);
    drv.pulse_sel(); // SEC
    drv.pulse_sel(); // MIN
    drv.pulse_down(); // 0 -> 59
    sb.check_time(0, 59, 0, "TC_4_4_2_MIN_59");
    drv.pulse_up();   // 59 -> 0
    sb.check_time(0, 0, 0, "TC_4_4_2_MIN_WRAPPED_0");
    sb.check_int(vif.adj_hour, 0, "adj_hour_not_incremented", "TC_4_4_2");
    finish_test_footer("4.4.2", "Minute wrap does not cascade to Hour buffer", errs, sb);
endtask

// 4.4.3: Snapshot capture on entering ADJ_SEC from background counters
task automatic run_tc_4_4_3(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("4.4.3", "Snapshot capture on entering ADJ_SEC from background counters");
    drv.reset_dut(10);
    // Let background counter reach 5 seconds
    drv.wait_sec_pulses(5);
    sb.check_time(0, 0, 5, "TC_4_4_3_BACKGROUND_AT_5");
    drv.pulse_sel(); // Enter ADJ_SEC
    sb.check_buffer(0, 0, 5, "TC_4_4_3_SNAPSHOT_CAPTURED");
    finish_test_footer("4.4.3", "Snapshot capture on entering ADJ_SEC from background counters", errs, sb);
endtask

// 4.4.4: Data persistence across mode transitions (SEC -> MIN -> HOUR)
task automatic run_tc_4_4_4(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("4.4.4", "Data persistence across mode transitions (SEC -> MIN -> HOUR)");
    drv.reset_dut(10);
    drv.pulse_sel(); // SEC
    repeat (45) drv.pulse_up(); // sec = 45
    sb.check_time(0, 0, 45, "TC_4_4_4_SEC_SET_45");
    drv.pulse_sel(); // MIN
    repeat (30) drv.pulse_up(); // min = 30
    sb.check_time(0, 30, 45, "TC_4_4_4_MIN_SET_30");
    drv.pulse_sel(); // HOUR
    repeat (10) drv.pulse_up(); // hour = 10
    sb.check_time(10, 30, 45, "TC_4_4_4_HOUR_SET_10");
    // Verify seconds (45) and minutes (30) persisted intact in ADJ_HOUR
    sb.check_int(vif.adj_sec, 45, "adj_sec_persisted", "TC_4_4_4");
    sb.check_int(vif.adj_min, 30, "adj_min_persisted", "TC_4_4_4");
    sb.check_int(vif.adj_hour, 10, "adj_hour_set", "TC_4_4_4");
    finish_test_footer("4.4.4", "Data persistence across mode transitions (SEC -> MIN -> HOUR)", errs, sb);
endtask

// 4.5.1: Real-Time Display Routing in MODE_RUN
task automatic run_tc_4_5_1(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("4.5.1", "Real-Time Display Routing in MODE_RUN");
    drv.reset_dut(10);
    drv.wait_sec_pulses(2);
    sb.check_signal((vif.s_out == vif.s_cnt), 1'b1, "s_out_equals_s_cnt", "TC_4_5_1");
    sb.check_signal((vif.m_out == vif.m_cnt), 1'b1, "m_out_equals_m_cnt", "TC_4_5_1");
    sb.check_signal((vif.h_out == vif.h_cnt), 1'b1, "h_out_equals_h_cnt", "TC_4_5_1");
    finish_test_footer("4.5.1", "Real-Time Display Routing in MODE_RUN", errs, sb);
endtask

// 4.5.2: Edit Buffer Display Routing in MODE_ADJ_*
task automatic run_tc_4_5_2(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("4.5.2", "Edit Buffer Display Routing in MODE_ADJ_*");
    drv.reset_dut(10);
    drv.pulse_sel(); // ADJ_SEC
    drv.pulse_up();  // sec = 1
    sb.check_signal((vif.s_out == vif.adj_sec), 1'b1, "s_out_equals_adj_sec", "TC_4_5_2");
    sb.check_signal((vif.m_out == vif.adj_min), 1'b1, "m_out_equals_adj_min", "TC_4_5_2");
    sb.check_signal((vif.h_out == vif.adj_hour), 1'b1, "h_out_equals_adj_hour", "TC_4_5_2");
    finish_test_footer("4.5.2", "Edit Buffer Display Routing in MODE_ADJ_*", errs, sb);
endtask

// 4.5.3: Output Switch combinational zero-latency update on UP/DOWN
task automatic run_tc_4_5_3(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("4.5.3", "Output Switch combinational zero-latency update on UP/DOWN");
    drv.reset_dut(10);
    drv.pulse_sel(); // ADJ_SEC
    drv.pulse_up(20, 25);
    @(posedge vif.clk); #1ns;
    // Exactly at clock cycle where adj_sec changes, s_out has the identical value
    sb.check_signal((vif.s_out === vif.adj_sec), 1'b1, "zero_latency_s_out", "TC_4_5_3");
    finish_test_footer("4.5.3", "Output Switch combinational zero-latency update on UP/DOWN", errs, sb);
endtask

// 4.5.4: Anti-glitch bypass during parallel load commit (load_en = 1)
task automatic run_tc_4_5_4(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    bit seen_load_en = 0;
    bit bypass_ok = 1;
    start_test_header("4.5.4", "Anti-glitch bypass during parallel load commit (load_en = 1)");
    drv.reset_dut(10);
    drv.pulse_sel(); // SEC
    drv.pulse_down(); // sec = 59
    drv.pulse_sel(); // MIN
    drv.pulse_down(); // min = 59
    drv.pulse_sel(); // HOUR
    drv.pulse_down(); // hour = 23
    // Trigger commit and verify bypass during load_en
    fork
        begin
            @(posedge vif.load_en);
            seen_load_en = 1;
            #1ns;
            if (vif.s_out !== vif.adj_sec || vif.m_out !== vif.adj_min || vif.h_out !== vif.adj_hour) begin
                bypass_ok = 0;
            end
        end
        drv.pulse_sel(); // HOUR -> RUN (commit)
    join
    sb.check_signal(seen_load_en, 1'b1, "seen_load_en", "TC_4_5_4");
    sb.check_signal(bypass_ok, 1'b1, "bypass_ok", "TC_4_5_4");
    finish_test_footer("4.5.4", "Anti-glitch bypass during parallel load commit (load_en = 1)", errs, sb);
endtask

// 4.5.5: Display output clean reversion on timeout rollback
task automatic run_tc_4_5_5(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("4.5.5", "Display output clean reversion on timeout rollback");
    drv.reset_dut(10);
    drv.pulse_sel(); // Enter ADJ_SEC
    repeat (2) drv.pulse_up(); // s_out shows 2
    sb.check_time(0, 0, 2, "TC_4_5_5_DISPLAY_EDIT");
    // Wait 5 sec_pulses for timeout
    repeat (5) @(posedge vif.sec_pulse);
    repeat (3) @(posedge vif.clk); #1ns;
    // Output must switch cleanly to background counter
    sb.check_time(vif.h_cnt, vif.m_cnt, vif.s_cnt, "TC_4_5_5_REVERT_BACKGROUND");
    finish_test_footer("4.5.5", "Display output clean reversion on timeout rollback", errs, sb);
endtask

`endif // TC_SEC4_BUFFERS_DISPLAY_SV
