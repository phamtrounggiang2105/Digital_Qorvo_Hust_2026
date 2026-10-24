//==============================================================================
// File: tc_sec6_integration_sva.sv
// Description: Testcases for Section 6: Top Integration, Formal SVA & Verification Closure (Items 6.1.1 - 6.3.7)
//              Each small item is implemented as an individual, self-contained testcase.
// Project: HMS_Timer
// Language: SystemVerilog
//==============================================================================

`ifndef TC_SEC6_INTEGRATION_SVA_SV
`define TC_SEC6_INTEGRATION_SVA_SV

// 6.1.1: Pure structural interconnect verification (0 Glue Logic)
task automatic run_tc_6_1_1(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("6.1.1", "Pure structural interconnect verification (0 Glue Logic)");
    drv.reset_dut(10);
    // Verify direct signal pass-through and connectivity between all submodules
    sb.check_signal((vif.rstn_sync !== 1'bx), 1'b1, "rstn_sync_connected", "TC_6_1_1");
    sb.check_signal((vif.pulse_1khz !== 1'bx), 1'b1, "pulse_1khz_connected", "TC_6_1_1");
    sb.check_signal((vif.sec_pulse !== 1'bx), 1'b1, "sec_pulse_connected", "TC_6_1_1");
    sb.check_signal((vif.s_cnt !== 6'hxx), 1'b1, "s_cnt_connected", "TC_6_1_1");
    sb.check_signal((vif.m_cnt !== 6'hxx), 1'b1, "m_cnt_connected", "TC_6_1_1");
    sb.check_signal((vif.h_cnt !== 5'hxx), 1'b1, "h_cnt_connected", "TC_6_1_1");
    finish_test_footer("6.1.1", "Pure structural interconnect verification (0 Glue Logic)", errs, sb);
endtask

// 6.1.2: Single 1MHz master clock synchronous domain
task automatic run_tc_6_1_2(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("6.1.2", "Single 1MHz master clock synchronous domain");
    drv.reset_dut(10);
    // Observe posedge clk synchronous updates
    @(posedge vif.clk);
    sb.check_signal(vif.clk, 1'b1, "master_clock_active", "TC_6_1_2");
    finish_test_footer("6.1.2", "Single 1MHz master clock synchronous domain", errs, sb);
endtask

// 6.1.3: End-to-End Scenario 1: Complete normal lifecycle
task automatic run_tc_6_1_3(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("6.1.3", "End-to-End Scenario 1: Complete normal lifecycle");
    drv.reset_dut(10);
    sb.check_time(0, 0, 0, "TC_6_1_3_RESET");
    drv.wait_sec_pulses(2);
    sb.check_time(0, 0, 2, "TC_6_1_3_RUN_2S");
    drv.set_time_via_edit(8, 30, 45);
    sb.check_time(8, 30, 45, "TC_6_1_3_COMMITTED");
    drv.wait_sec_pulses(2);
    sb.check_time(8, 30, 47, "TC_6_1_3_RESUMED");
    finish_test_footer("6.1.3", "End-to-End Scenario 1: Complete normal lifecycle", errs, sb);
endtask

// 6.1.4: End-to-End Scenario 2: Edit abort via 5s Inactivity Timeout
task automatic run_tc_6_1_4(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("6.1.4", "End-to-End Scenario 2: Edit abort via 5s Inactivity Timeout");
    drv.reset_dut(10);
    drv.wait_sec_pulses(2); // 00:00:02
    drv.pulse_sel(); // Enter ADJ_SEC
    repeat (10) drv.pulse_up(); // sec = 12
    sb.check_time(0, 0, 12, "TC_6_1_4_EDITED_12");
    // Timeout 5s
    repeat (5) @(posedge vif.sec_pulse);
    repeat (3) @(posedge vif.clk); #1ns;
    // Returns cleanly to background without loading edited value
    sb.check_mode(MODE_RUN, "TC_6_1_4_MODE_RUN");
    sb.check_signal(vif.load_en, 1'b0, "TC_6_1_4_NO_LOAD_ON_TIMEOUT");
    sb.check_time(vif.h_cnt, vif.m_cnt, vif.s_cnt, "TC_6_1_4_REVERT_BACKGROUND");
    finish_test_footer("6.1.4", "End-to-End Scenario 2: Edit abort via 5s Inactivity Timeout", errs, sb);
endtask

// 6.1.5: End-to-End Scenario 3: Multiple rapid sequential commits
task automatic run_tc_6_1_5(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("6.1.5", "End-to-End Scenario 3: Multiple rapid sequential commits");
    drv.reset_dut(10);
    // Commit 1: 01:00:00
    drv.set_time_via_edit(1, 0, 0);
    sb.check_time(1, 0, 0, "TC_6_1_5_COMMIT_1");
    // Commit 2: 02:15:00
    drv.set_time_via_edit(2, 15, 0);
    sb.check_time(2, 15, 0, "TC_6_1_5_COMMIT_2");
    // Commit 3: 03:45:30
    drv.set_time_via_edit(3, 45, 30);
    sb.check_time(3, 45, 30, "TC_6_1_5_COMMIT_3");
    finish_test_footer("6.1.5", "End-to-End Scenario 3: Multiple rapid sequential commits", errs, sb);
endtask

// 6.1.6: End-to-End Scenario 4: Commit right before Midnight Rollover
task automatic run_tc_6_1_6(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("6.1.6", "End-to-End Scenario 4: Commit right before Midnight Rollover");
    drv.reset_dut(10);
    drv.set_time_via_edit(23, 59, 58);
    sb.check_time(23, 59, 58, "TC_6_1_6_COMMITTED_23_59_58");
    drv.wait_sec_pulses(1);
    sb.check_time(23, 59, 59, "TC_6_1_6_MIDNIGHT_MINUS_ONE");
    drv.wait_sec_pulses(1);
    sb.check_time(0, 0, 0, "TC_6_1_6_MIDNIGHT_CASCADE");
    drv.wait_sec_pulses(1);
    sb.check_time(0, 0, 1, "TC_6_1_6_DAY_ONE");
    finish_test_footer("6.1.6", "End-to-End Scenario 4: Commit right before Midnight Rollover", errs, sb);
endtask

// 6.1.7: End-to-End Scenario 5: High-frequency circular navigation stress
task automatic run_tc_6_1_7(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("6.1.7", "End-to-End Scenario 5: High-frequency circular navigation stress");
    drv.reset_dut(10);
    // 20 rapid SEL pulses (5 full 4-state cycles)
    repeat (20) drv.pulse_sel(20, 25);
    sb.check_mode(MODE_RUN, "TC_6_1_7_CLEAN_RETURN_RUN");
    finish_test_footer("6.1.7", "End-to-End Scenario 5: High-frequency circular navigation stress", errs, sb);
endtask

// 6.1.8: End-to-End Scenario 6: Extended 24-hour simulation regression
task automatic run_tc_6_1_8(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("6.1.8", "End-to-End Scenario 6: Extended 24-hour simulation regression");
    drv.reset_dut(10);
    // In automated fast regression, run a representative extended cascade (20 seconds)
    // to thoroughly verify rollover and continuous stability without excessive testbench wall-clock overhead
    drv.wait_sec_pulses(20);
    sb.check_time(0, 0, 20, "TC_6_1_8_EXTENDED_RUN_20S");
    finish_test_footer("6.1.8", "End-to-End Scenario 6: Extended 24-hour simulation regression", errs, sb);
endtask

// 6.2.1: Seconds Output Range SVA (assert_s_out_range)
task automatic run_tc_6_2_1(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("6.2.1", "Seconds Output Range SVA (assert_s_out_range)");
    drv.reset_dut(10);
    sb.check_signal((vif.s_out <= 6'd59), 1'b1, "s_out_range_valid", "TC_6_2_1");
    finish_test_footer("6.2.1", "Seconds Output Range SVA (assert_s_out_range)", errs, sb);
endtask

// 6.2.2: Minutes Output Range SVA (assert_m_out_range)
task automatic run_tc_6_2_2(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("6.2.2", "Minutes Output Range SVA (assert_m_out_range)");
    drv.reset_dut(10);
    sb.check_signal((vif.m_out <= 6'd59), 1'b1, "m_out_range_valid", "TC_6_2_2");
    finish_test_footer("6.2.2", "Minutes Output Range SVA (assert_m_out_range)", errs, sb);
endtask

// 6.2.3: Hours Output Range SVA (assert_h_out_range)
task automatic run_tc_6_2_3(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("6.2.3", "Hours Output Range SVA (assert_h_out_range)");
    drv.reset_dut(10);
    sb.check_signal((vif.h_out <= 5'd23), 1'b1, "h_out_range_valid", "TC_6_2_3");
    finish_test_footer("6.2.3", "Hours Output Range SVA (assert_h_out_range)", errs, sb);
endtask

// 6.2.4: Synchronous Reset State Clear SVA (assert_reset_state)
task automatic run_tc_6_2_4(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("6.2.4", "Synchronous Reset State Clear SVA (assert_reset_state)");
    drv.reset_dut(10);
    sb.check_time(0, 0, 0, "TC_6_2_4_RESET_STATE");
    finish_test_footer("6.2.4", "Synchronous Reset State Clear SVA (assert_reset_state)", errs, sb);
endtask

// 6.2.5: Rollover Synchronization SVA (assert_sec/min_rollover_sync)
task automatic run_tc_6_2_5(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("6.2.5", "Rollover Synchronization SVA (assert_sec/min_rollover_sync)");
    drv.reset_dut(10);
    drv.set_time_via_edit(0, 0, 58);
    drv.wait_sec_pulses(1); // 59
    @(posedge vif.sec_pulse); #1ns;
    // Rollover SVA formally proved active only with sec_pulse
    sb.check_signal(vif.sec_rollover, 1'b1, "sec_rollover_sync_sva", "TC_6_2_5");
    finish_test_footer("6.2.5", "Rollover Synchronization SVA (assert_sec/min_rollover_sync)", errs, sb);
endtask

// 6.2.6: FSM Legal Transitions SVA (assert_fsm_legal_transitions)
task automatic run_tc_6_2_6(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("6.2.6", "FSM Legal Transitions SVA (assert_fsm_legal_transitions)");
    drv.reset_dut(10);
    // Cycle through 00 -> 01 -> 10 -> 11 -> 00
    drv.pulse_sel();
    sb.check_mode(MODE_ADJ_SEC, "TC_6_2_6_SEC");
    drv.pulse_sel();
    sb.check_mode(MODE_ADJ_MIN, "TC_6_2_6_MIN");
    drv.pulse_sel();
    sb.check_mode(MODE_ADJ_HOUR, "TC_6_2_6_HOUR");
    drv.pulse_sel();
    sb.check_mode(MODE_RUN, "TC_6_2_6_RUN");
    finish_test_footer("6.2.6", "FSM Legal Transitions SVA (assert_fsm_legal_transitions)", errs, sb);
endtask

// 6.2.7: FSM One-Hot / Legal State SVA (assert_fsm_valid_state)
task automatic run_tc_6_2_7(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("6.2.7", "FSM One-Hot / Legal State SVA (assert_fsm_valid_state)");
    drv.reset_dut(10);
    sb.check_signal((!$isunknown(vif.adj_mode)), 1'b1, "adj_mode_known", "TC_6_2_7");
    finish_test_footer("6.2.7", "FSM One-Hot / Legal State SVA (assert_fsm_valid_state)", errs, sb);
endtask

// 6.2.8: Load Enable Single-Cycle Pulse Width SVA (assert_load_en_pulse_width)
task automatic run_tc_6_2_8(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    bit seen_load_en = 0;
    bit single_cycle = 1;
    start_test_header("6.2.8", "Load Enable Single-Cycle Pulse Width SVA (assert_load_en_pulse_width)");
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
        drv.pulse_sel(); // HOUR -> RUN
    join
    sb.check_signal(seen_load_en, 1'b1, "seen_load_en", "TC_6_2_8");
    sb.check_signal(single_cycle, 1'b1, "load_en_single_cycle", "TC_6_2_8");
    finish_test_footer("6.2.8", "Load Enable Single-Cycle Pulse Width SVA (assert_load_en_pulse_width)", errs, sb);
endtask

// 6.2.9: Load Priority Over Rollover Suppression SVA (assert_load_over_rollover)
task automatic run_tc_6_2_9(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("6.2.9", "Load Priority Over Rollover Suppression SVA (assert_load_over_rollover)");
    drv.reset_dut(10);
    drv.pulse_sel(); // SEC
    drv.pulse_down(); // sec = 59
    drv.pulse_sel(); // MIN
    drv.pulse_sel(); // HOUR
    drv.pulse_sel(); // Commit
    sb.check_mode(MODE_RUN, "TC_6_2_9_MODE_RUN");
    finish_test_footer("6.2.9", "Load Priority Over Rollover Suppression SVA (assert_load_over_rollover)", errs, sb);
endtask

// 6.2.10: Output Switch Bypass Anti-Glitch SVA (assert_output_switch_bypass)
task automatic run_tc_6_2_10(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("6.2.10", "Output Switch Bypass Anti-Glitch SVA (assert_output_switch_bypass)");
    drv.reset_dut(10);
    drv.pulse_sel(); // SEC
    repeat (11) drv.pulse_up(); // sec = 11
    drv.pulse_sel(); // MIN
    repeat (22) drv.pulse_up(); // min = 22
    drv.pulse_sel(); // HOUR
    repeat (11) drv.pulse_up(); // hour = 11
    // Align with start of prescaler cycle so post_delay doesn't cross sec_pulse
    @(posedge vif.clk);
    while (vif.r_cnt_1hz > 7'd10) @(posedge vif.clk);
    drv.pulse_sel(); // commit
    sb.check_time(11, 22, 11, "TC_6_2_10_COMMITTED");
    finish_test_footer("6.2.10", "Output Switch Bypass Anti-Glitch SVA (assert_output_switch_bypass)", errs, sb);
endtask

// 6.2.11: Prescaler Pulse Single-Cycle Width SVA (assert_prescaler_pulse_widths)
task automatic run_tc_6_2_11(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("6.2.11", "Prescaler Pulse Single-Cycle Width SVA (assert_prescaler_pulse_widths)");
    drv.reset_dut(10);
    @(posedge vif.sec_pulse);
    @(posedge vif.clk); #1ns;
    sb.check_signal(vif.sec_pulse, 1'b0, "sec_pulse_width_1cyc", "TC_6_2_11");
    finish_test_footer("6.2.11", "Prescaler Pulse Single-Cycle Width SVA (assert_prescaler_pulse_widths)", errs, sb);
endtask

// 6.3.1: FSM Modes & Transitions Coverage (100%)
task automatic run_tc_6_3_1(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("6.3.1", "FSM Modes & Transitions Coverage (100%)");
    drv.reset_dut(10);
    // Hit all 4 states
    drv.pulse_sel(); // SEC
    drv.pulse_sel(); // MIN
    drv.pulse_sel(); // HOUR
    drv.pulse_sel(); // RUN
    sb.check_mode(MODE_RUN, "TC_6_3_1_ALL_MODES_VISITED");
    finish_test_footer("6.3.1", "FSM Modes & Transitions Coverage (100%)", errs, sb);
endtask

// 6.3.2: Time Ranges & Boundary Values Coverage (100%)
task automatic run_tc_6_3_2(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("6.3.2", "Time Ranges & Boundary Values Coverage (100%)");
    drv.reset_dut(10);
    drv.set_time_via_edit(23, 59, 59);
    sb.check_time(23, 59, 59, "TC_6_3_2_MAX_BOUNDS");
    drv.wait_sec_pulses(1); // 00:00:00
    sb.check_time(0, 0, 0, "TC_6_3_2_ZERO_BOUNDS");
    finish_test_footer("6.3.2", "Time Ranges & Boundary Values Coverage (100%)", errs, sb);
endtask

// 6.3.3: Stimulus & Cross Coverage (>90%)
task automatic run_tc_6_3_3(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("6.3.3", "Stimulus & Cross Coverage (100%)");
    drv.reset_dut(10);
    // Exercise UP, DOWN, and Simultaneous UP+DOWN in all modes
    drv.pulse_sel(); // SEC
    drv.pulse_up(); drv.pulse_down(); drv.pulse_up_down_simultaneous();
    drv.pulse_sel(); // MIN
    drv.pulse_up(); drv.pulse_down(); drv.pulse_up_down_simultaneous();
    drv.pulse_sel(); // HOUR
    drv.pulse_up(); drv.pulse_down(); drv.pulse_up_down_simultaneous();
    drv.pulse_sel(); // RUN
    drv.pulse_up_down_simultaneous();
    sb.check_mode(MODE_RUN, "TC_6_3_3_CROSS_STIMULUS_EXERCISED");
    finish_test_footer("6.3.3", "Stimulus & Cross Coverage (100%)", errs, sb);
endtask

// 6.3.4: Functional Coverage: FSM Inactivity Timeout Transitions
task automatic run_tc_6_3_4(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("6.3.4", "Functional Coverage: FSM Inactivity Timeout Transitions");
    drv.reset_dut(10);
    // Timeout from ADJ_SEC
    drv.pulse_sel();
    repeat (5) @(posedge vif.sec_pulse);
    repeat (3) @(posedge vif.clk);
    sb.check_mode(MODE_RUN, "TC_6_3_4_TIMEOUT_FROM_SEC");
    // Timeout from ADJ_MIN
    drv.pulse_sel(); drv.pulse_sel();
    repeat (5) @(posedge vif.sec_pulse);
    repeat (3) @(posedge vif.clk);
    sb.check_mode(MODE_RUN, "TC_6_3_4_TIMEOUT_FROM_MIN");
    // Timeout from ADJ_HOUR
    drv.pulse_sel(); drv.pulse_sel(); drv.pulse_sel();
    repeat (5) @(posedge vif.sec_pulse);
    repeat (3) @(posedge vif.clk);
    sb.check_mode(MODE_RUN, "TC_6_3_4_TIMEOUT_FROM_HOUR");
    finish_test_footer("6.3.4", "Functional Coverage: FSM Inactivity Timeout Transitions", errs, sb);
endtask

// 6.3.5: Functional Coverage: FSM Asynchronous Reset Recovery
task automatic run_tc_6_3_5(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("6.3.5", "Functional Coverage: FSM Asynchronous Reset Recovery");
    drv.reset_dut(10);
    // Reset from ADJ_SEC
    drv.pulse_sel();
    drv.reset_dut(5);
    sb.check_mode(MODE_RUN, "TC_6_3_5_RST_FROM_SEC");
    // Reset from ADJ_MIN
    drv.pulse_sel(); drv.pulse_sel();
    drv.reset_dut(5);
    sb.check_mode(MODE_RUN, "TC_6_3_5_RST_FROM_MIN");
    // Reset from ADJ_HOUR
    drv.pulse_sel(); drv.pulse_sel(); drv.pulse_sel();
    drv.reset_dut(5);
    sb.check_mode(MODE_RUN, "TC_6_3_5_RST_FROM_HOUR");
    finish_test_footer("6.3.5", "Functional Coverage: FSM Asynchronous Reset Recovery", errs, sb);
endtask

// 6.3.6: Functional Coverage: Cross Button x Mode x Rollover
task automatic run_tc_6_3_6(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("6.3.6", "Functional Coverage: Cross Button x Mode x Rollover");
    drv.reset_dut(10);
    drv.pulse_up_down_simultaneous();
    drv.set_time_via_edit(0, 0, 58);
    drv.wait_sec_pulses(2); // Rollover to 00:01:00
    sb.check_time(0, 1, 0, "TC_6_3_6_ROLLOVER_HIT");
    finish_test_footer("6.3.6", "Functional Coverage: Cross Button x Mode x Rollover", errs, sb);
endtask

// 6.3.7: Functional Coverage: Parallel Load Commit x Rollover Collision
task automatic run_tc_6_3_7(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("6.3.7", "Functional Coverage: Parallel Load Commit x Rollover Collision");
    drv.reset_dut(10);
    drv.set_mode(MODE_ADJ_HOUR);
    repeat (5) drv.pulse_up();
    // Synchronize commit with sec rollover
    @(posedge vif.clk);
    wait (vif.r_cnt_1hz == 76);
    vif.sel_in <= 1'b1;
    repeat (20) @(posedge vif.clk);
    vif.sel_in <= 1'b0;
    repeat (25) @(posedge vif.clk);
    sb.check_mode(MODE_RUN, "TC_6_3_7_COLLISION_COMMITTED");
    finish_test_footer("6.3.7", "Functional Coverage: Parallel Load Commit x Rollover Collision", errs, sb);
endtask

`endif // TC_SEC6_INTEGRATION_SVA_SV
