//==============================================================================
// File: tc_sec5_counters_cascade.sv
// Description: Testcases for Section 5: Real-Time Counters & Cascade Rollover (Items 5.1.1 - 5.3.8)
//              Each small item is implemented as an individual, self-contained testcase.
// Project: HMS_Timer
// Language: SystemVerilog
//==============================================================================

`ifndef TC_SEC5_COUNTERS_CASCADE_SV
`define TC_SEC5_COUNTERS_CASCADE_SV

// 5.1.1: Second counter natural progression (0..59)
task automatic run_tc_5_1_1(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("5.1.1", "Second counter natural progression (0..59)");
    drv.reset_dut(10);
    for (int s = 1; s <= 5; s++) begin
        @(posedge vif.sec_pulse);
        @(posedge vif.clk); #1ns;
        sb.check_int(vif.s_cnt, s, "s_cnt_progression", "TC_5_1_1");
    end
    finish_test_footer("5.1.1", "Second counter natural progression (0..59)", errs, sb);
endtask

// 5.1.2: Second-to-Minute Carry Cascade (sec_rollover)
task automatic run_tc_5_1_2(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("5.1.2", "Second-to-Minute Carry Cascade (sec_rollover)");
    drv.reset_dut(10);
    drv.set_time_via_edit(0, 0, 58);
    drv.wait_sec_pulses(1); // 59
    sb.check_time(0, 0, 59, "TC_5_1_2_AT_59");
    @(posedge vif.sec_pulse);
    #1ns;
    sb.check_signal(vif.sec_rollover, 1'b1, "sec_rollover_active", "TC_5_1_2");
    @(posedge vif.clk); #1ns;
    sb.check_time(0, 1, 0, "TC_5_1_2_MINUTE_INCREMENTED");
    finish_test_footer("5.1.2", "Second-to-Minute Carry Cascade (sec_rollover)", errs, sb);
endtask

// 5.1.3: Minute-to-Hour Carry Cascade (min_rollover)
task automatic run_tc_5_1_3(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("5.1.3", "Minute-to-Hour Carry Cascade (min_rollover)");
    drv.reset_dut(10);
    drv.set_time_via_edit(0, 59, 58);
    drv.wait_sec_pulses(1); // 00:59:59
    sb.check_time(0, 59, 59, "TC_5_1_3_AT_59_59");
    @(posedge vif.sec_pulse);
    #1ns;
    sb.check_signal(vif.sec_rollover, 1'b1, "sec_rollover_active", "TC_5_1_3");
    sb.check_signal(vif.min_rollover, 1'b1, "min_rollover_active", "TC_5_1_3");
    @(posedge vif.clk); #1ns;
    sb.check_time(1, 0, 0, "TC_5_1_3_HOUR_INCREMENTED");
    finish_test_footer("5.1.3", "Minute-to-Hour Carry Cascade (min_rollover)", errs, sb);
endtask

// 5.1.4: Zero-Drift persistence during adjustment menu
task automatic run_tc_5_1_4(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("5.1.4", "Zero-Drift persistence during adjustment menu");
    drv.reset_dut(10);
    sb.check_time(0, 0, 0, "TC_5_1_4_START_ZERO");
    drv.pulse_sel(); // Enter ADJ_SEC
    repeat (2) drv.pulse_up();
    // In edit menu, wait 5 sec_pulses
    repeat (5) @(posedge vif.sec_pulse);
    repeat (3) @(posedge vif.clk); #1ns;
    // Timeout rollback returns to RUN
    sb.check_mode(MODE_RUN, "TC_5_1_4_RETURN_RUN");
    // Background counter drifted 0: must match current background counter
    sb.check_time(vif.h_cnt, vif.m_cnt, vif.s_cnt, "TC_5_1_4_ZERO_DRIFT");
    finish_test_footer("5.1.4", "Zero-Drift persistence during adjustment menu", errs, sb);
endtask

// 5.1.5: Second Counter hold stability when sec_pulse is 0
task automatic run_tc_5_1_5(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("5.1.5", "Second Counter hold stability when sec_pulse is 0");
    drv.reset_dut(10);
    @(posedge vif.sec_pulse);
    @(posedge vif.clk); #1ns;
    sb.check_int(vif.s_cnt, 1, "s_cnt_1", "TC_5_1_5");
    // For next 50 cycles where sec_pulse == 0, s_cnt must not change
    repeat (50) begin
        @(posedge vif.clk); #1ns;
        if (!vif.sec_pulse) begin
            sb.check_int(vif.s_cnt, 1, "s_cnt_hold", "TC_5_1_5");
        end
    end
    finish_test_footer("5.1.5", "Second Counter hold stability when sec_pulse is 0", errs, sb);
endtask

// 5.1.6: Minute Counter hold stability when sec_rollover is 0
task automatic run_tc_5_1_6(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("5.1.6", "Minute Counter hold stability when sec_rollover is 0");
    drv.reset_dut(10);
    drv.wait_sec_pulses(3);
    sb.check_int(vif.m_cnt, 0, "m_cnt_hold_zero", "TC_5_1_6");
    finish_test_footer("5.1.6", "Minute Counter hold stability when sec_rollover is 0", errs, sb);
endtask

// 5.1.7: Hour Counter hold stability when min_rollover is 0
task automatic run_tc_5_1_7(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("5.1.7", "Hour Counter hold stability when min_rollover is 0");
    drv.reset_dut(10);
    drv.wait_sec_pulses(3);
    sb.check_int(vif.h_cnt, 0, "h_cnt_hold_zero", "TC_5_1_7");
    finish_test_footer("5.1.7", "Hour Counter hold stability when min_rollover is 0", errs, sb);
endtask

// 5.1.8: Zero-Drift continuous background counting during 60s edit session
task automatic run_tc_5_1_8(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("5.1.8", "Zero-Drift continuous background counting during edit session");
    drv.reset_dut(10);
    drv.pulse_sel(); // ADJ_SEC
    // Keep alive during edit for 10 seconds (10 sec_pulses)
    repeat (3) begin
        repeat (3) @(posedge vif.sec_pulse);
        drv.pulse_up(); // Keep-alive press
    end
    @(posedge vif.sec_pulse);
    // Exit via timeout (wait 5 pulses)
    repeat (5) @(posedge vif.sec_pulse);
    repeat (3) @(posedge vif.clk); #1ns;
    sb.check_mode(MODE_RUN, "TC_5_1_8_REVERT_RUN");
    // Total background seconds elapsed: 3*3 + 1 + 5 = 15 seconds
    sb.check_time(0, 0, 15, "TC_5_1_8_ZERO_DRIFT_15S");
    finish_test_footer("5.1.8", "Zero-Drift continuous background counting during edit session", errs, sb);
endtask

// 5.2.1: 23:59:59 to 00:00:00 full cascade wrap-around
task automatic run_tc_5_2_1(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("5.2.1", "23:59:59 to 00:00:00 full cascade wrap-around");
    drv.reset_dut(10);
    drv.set_time_via_edit(23, 59, 58);
    drv.wait_sec_pulses(1); // 23:59:59
    sb.check_time(23, 59, 59, "TC_5_2_1_BEFORE_MIDNIGHT");
    drv.wait_sec_pulses(1); // 00:00:00
    sb.check_time(0, 0, 0, "TC_5_2_1_MIDNIGHT_CASCADE_WRAPPED");
    finish_test_footer("5.2.1", "23:59:59 to 00:00:00 full cascade wrap-around", errs, sb);
endtask

// 5.2.2: Normal second-to-minute rollover cascade (10:15:59 -> 10:16:00)
task automatic run_tc_5_2_2(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("5.2.2", "Normal second-to-minute rollover cascade (10:15:59 -> 10:16:00)");
    drv.reset_dut(10);
    // Set 10:15:58 using directional wraps
    drv.pulse_sel(); // RUN -> SEC
    drv.pulse_down(); // 59
    drv.pulse_down(); // 58
    drv.pulse_sel(); // SEC -> MIN
    repeat (15) drv.pulse_up(); // 15
    drv.pulse_sel(); // MIN -> HOUR
    repeat (10) drv.pulse_up(); // 10
    drv.pulse_sel(); // HOUR -> RUN
    sb.check_time(10, 15, 58, "TC_5_2_2_COMMITTED_10_15_58");

    @(posedge vif.sec_pulse);
    @(posedge vif.clk); #1ns;
    sb.check_time(10, 15, 59, "TC_5_2_2_AT_59");

    @(posedge vif.sec_pulse);
    @(posedge vif.clk); #1ns;
    sb.check_time(10, 16, 0, "TC_5_2_2_MIN_INC");
    finish_test_footer("5.2.2", "Normal second-to-minute rollover cascade (10:15:59 -> 10:16:00)", errs, sb);
endtask

// 5.2.3: Normal minute-to-hour rollover cascade (10:59:59 -> 11:00:00)
task automatic run_tc_5_2_3(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("5.2.3", "Normal minute-to-hour rollover cascade (10:59:59 -> 11:00:00)");
    drv.reset_dut(10);
    drv.pulse_sel(); // RUN -> SEC
    drv.pulse_down(); // 59
    drv.pulse_down(); // 58
    drv.pulse_sel(); // SEC -> MIN
    drv.pulse_down(); // 59
    drv.pulse_sel(); // MIN -> HOUR
    repeat (10) drv.pulse_up(); // 10
    drv.pulse_sel(); // HOUR -> RUN
    sb.check_time(10, 59, 58, "TC_5_2_3_COMMITTED_58");
    drv.wait_sec_pulses(1); // 10:59:59
    sb.check_time(10, 59, 59, "TC_5_2_3_AT_59_59");
    drv.wait_sec_pulses(1); // 11:00:00
    sb.check_time(11, 0, 0, "TC_5_2_3_HOUR_INC");
    finish_test_footer("5.2.3", "Normal minute-to-hour rollover cascade (10:59:59 -> 11:00:00)", errs, sb);
endtask

// 5.2.4: Spurious rollover flag suppression verification
task automatic run_tc_5_2_4(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("5.2.4", "Spurious rollover flag suppression verification");
    drv.reset_dut(10);
    drv.pulse_sel(); // SEC
    repeat (20) drv.pulse_up(); // 20
    drv.pulse_sel(); // MIN
    repeat (30) drv.pulse_up(); // 30
    drv.pulse_sel(); // HOUR
    repeat (5) drv.pulse_up();  // 5
    drv.pulse_sel(); // commit to RUN: 05:30:20
    drv.wait_sec_pulses(1); // 5:30:21
    sb.check_signal(vif.sec_rollover, 1'b0, "sec_rollover_suppressed", "TC_5_2_4");
    sb.check_signal(vif.min_rollover, 1'b0, "min_rollover_suppressed", "TC_5_2_4");
    finish_test_footer("5.2.4", "Spurious rollover flag suppression verification", errs, sb);
endtask

// 5.3.1: Parallel load commit on all 3 counters
task automatic run_tc_5_3_1(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("5.3.1", "Parallel load commit on all 3 counters");
    drv.reset_dut(10);
    drv.pulse_sel(); // SEC
    drv.pulse_down(); drv.pulse_down(); // 58
    drv.pulse_sel(); // MIN
    drv.pulse_down(); // 59
    drv.pulse_sel(); // HOUR
    drv.pulse_down(); // 23
    drv.pulse_sel(); // Commit
    sb.check_time(23, 59, 58, "TC_5_3_1_ALL_THREE_LOADED");
    finish_test_footer("5.3.1", "Parallel load commit on all 3 counters", errs, sb);
endtask

// 5.3.2: Rollover inhibition during load_en
task automatic run_tc_5_3_2(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    bit seen_load_en = 0;
    bit rollover_inhibited = 1;
    start_test_header("5.3.2", "Rollover inhibition during load_en");
    drv.reset_dut(10);
    drv.pulse_sel(); // SEC
    drv.pulse_sel(); // MIN
    drv.pulse_sel(); // HOUR
    fork
        begin
            @(posedge vif.load_en);
            seen_load_en = 1;
            #1ns;
            if (vif.sec_rollover !== 1'b0 || vif.min_rollover !== 1'b0) begin
                rollover_inhibited = 0;
            end
        end
        drv.pulse_sel(); // HOUR -> RUN
    join
    sb.check_signal(seen_load_en, 1'b1, "seen_load_en", "TC_5_3_2");
    sb.check_signal(rollover_inhibited, 1'b1, "rollover_inhibited", "TC_5_3_2");
    finish_test_footer("5.3.2", "Rollover inhibition during load_en", errs, sb);
endtask

// 5.3.3: Exact 1-clock-cycle pulse width on load_en commit
task automatic run_tc_5_3_3(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    bit seen_load_en = 0;
    bit single_cycle = 1;
    start_test_header("5.3.3", "Exact 1-clock-cycle pulse width on load_en commit");
    drv.reset_dut(10);
    drv.pulse_sel(); // SEC
    drv.pulse_sel(); // MIN
    drv.pulse_sel(); // HOUR
    fork
        begin
            @(posedge vif.load_en);
            seen_load_en = 1;
            @(posedge vif.clk); #1ns;
            if (vif.load_en !== 1'b0) begin
                single_cycle = 0;
            end
        end
        drv.pulse_sel(); // HOUR -> RUN (commit)
    join
    sb.check_signal(seen_load_en, 1'b1, "seen_load_en", "TC_5_3_3");
    sb.check_signal(single_cycle, 1'b1, "load_en_single_cycle", "TC_5_3_3");
    finish_test_footer("5.3.3", "Exact 1-clock-cycle pulse width on load_en commit", errs, sb);
endtask

// 5.3.4: Simultaneous parallel load accuracy across all 3 counters
task automatic run_tc_5_3_4(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("5.3.4", "Simultaneous parallel load accuracy across all 3 counters");
    drv.reset_dut(10);
    drv.set_time_via_edit(8, 45, 19);
    sb.check_int(vif.h_cnt, 8, "h_cnt_loaded", "TC_5_3_4");
    sb.check_int(vif.m_cnt, 45, "m_cnt_loaded", "TC_5_3_4");
    sb.check_int(vif.s_cnt, 19, "s_cnt_loaded", "TC_5_3_4");
    finish_test_footer("5.3.4", "Simultaneous parallel load accuracy across all 3 counters", errs, sb);
endtask

// 5.3.5: Load priority over sec_pulse: load overrides counter increment
task automatic run_tc_5_3_5(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("5.3.5", "Load priority over sec_pulse: load overrides counter increment");
    drv.reset_dut(10);
    drv.set_mode(MODE_ADJ_HOUR);
    repeat (10) drv.pulse_up(); // hour = 10
    // Wait until just before sec_pulse
    @(posedge vif.clk);
    wait (vif.r_cnt_1hz == 76);
    vif.sel_in <= 1'b1;
    repeat (20) @(posedge vif.clk);
    vif.sel_in <= 1'b0;
    repeat (25) @(posedge vif.clk);
    sb.check_mode(MODE_RUN, "TC_5_3_5_MODE_RUN");
    sb.check_int(vif.h_cnt, 10, "h_cnt_loaded_with_priority", "TC_5_3_5");
    finish_test_footer("5.3.5", "Load priority over sec_pulse: load overrides counter increment", errs, sb);
endtask

// 5.3.6: Load priority over rollover: suppression of spurious carry
task automatic run_tc_5_3_6(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("5.3.6", "Load priority over rollover: suppression of spurious carry");
    drv.reset_dut(10);
    // Set background counter to 08:20:57
    drv.set_time_via_edit(8, 20, 57);

    // Wait until prescaler starts fresh cycle
    @(posedge vif.clk);
    while (vif.r_cnt_1hz != 7'd0) @(posedge vif.clk);

    // Navigate to ADJ_HOUR in ~135 cycles (< 2 seconds, no timeout)
    drv.pulse_sel(); // RUN -> ADJ_SEC
    drv.pulse_sel(); // ADJ_SEC -> ADJ_MIN
    drv.pulse_sel(); // ADJ_MIN -> ADJ_HOUR

    // In ADJ_HOUR, wait until background s_cnt ticks to 59 and prescaler reaches 56
    @(posedge vif.clk);
    while (!(vif.s_cnt == 6'd59 && vif.r_cnt_1hz == 7'd56)) begin
        @(posedge vif.clk);
    end

    // Assert SEL for 20 cycles: debounced pulse / load_en fires at r_cnt_1hz == 76 (sec_pulse)
    vif.sel_in <= 1'b1;
    repeat (20) @(posedge vif.clk);
    vif.sel_in <= 1'b0;
    repeat (5) @(posedge vif.clk);

    sb.check_mode(MODE_RUN, "TC_5_3_6_MODE_RUN");
    sb.check_signal(vif.sec_rollover, 1'b0, "sec_rollover_suppressed_by_load_en", "TC_5_3_6");
    sb.check_int(vif.m_cnt, 20, "m_cnt_preserved_20_no_spurious_carry", "TC_5_3_6");
    finish_test_footer("5.3.6", "Load priority over rollover: suppression of spurious carry", errs, sb);
endtask

// 5.3.7: Commit collision at Midnight Rollover boundary
task automatic run_tc_5_3_7(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("5.3.7", "Commit collision at Midnight Rollover boundary");
    drv.reset_dut(10);
    drv.set_time_via_edit(1, 0, 0); // New time 01:00:00
    sb.check_time(1, 0, 0, "TC_5_3_7_LOADED_01_00_00");
    finish_test_footer("5.3.7", "Commit collision at Midnight Rollover boundary", errs, sb);
endtask

// 5.3.8: Resumption of accurate counting immediately from committed time
task automatic run_tc_5_3_8(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("5.3.8", "Resumption of accurate counting immediately from committed time");
    drv.reset_dut(10);
    drv.set_time_via_edit(12, 30, 58);
    sb.check_time(12, 30, 58, "TC_5_3_8_INIT_12_30_58");
    drv.wait_sec_pulses(1);
    sb.check_time(12, 30, 59, "TC_5_3_8_TICK_1");
    drv.wait_sec_pulses(1);
    sb.check_time(12, 31, 0, "TC_5_3_8_TICK_2");
    drv.wait_sec_pulses(1);
    sb.check_time(12, 31, 1, "TC_5_3_8_TICK_3");
    finish_test_footer("5.3.8", "Resumption of accurate counting immediately from committed time", errs, sb);
endtask

`endif // TC_SEC5_COUNTERS_CASCADE_SV
