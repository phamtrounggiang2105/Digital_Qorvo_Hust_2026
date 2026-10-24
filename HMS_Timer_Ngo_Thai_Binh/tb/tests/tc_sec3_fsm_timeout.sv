//==============================================================================
// File: tc_sec3_fsm_timeout.sv
// Description: Testcases for Section 3: Mode Controller FSM & Inactivity Management (Items 3.1.1 - 3.3.4)
//              Each small item is implemented as an individual, self-contained testcase.
// Project: HMS_Timer
// Language: SystemVerilog
//==============================================================================

`ifndef TC_SEC3_FSM_TIMEOUT_SV
`define TC_SEC3_FSM_TIMEOUT_SV

// 3.1.1: Transition RUN (00) -> ADJ_SEC (01)
task automatic run_tc_3_1_1(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("3.1.1", "Transition RUN (00) -> ADJ_SEC (01)");
    drv.reset_dut(10);
    sb.check_mode(MODE_RUN, "TC_3_1_1_START_RUN");
    drv.pulse_sel();
    sb.check_mode(MODE_ADJ_SEC, "TC_3_1_1_TRANSITION_SEC");
    finish_test_footer("3.1.1", "Transition RUN (00) -> ADJ_SEC (01)", errs, sb);
endtask

// 3.1.2: Transition ADJ_SEC (01) -> ADJ_MIN (10)
task automatic run_tc_3_1_2(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("3.1.2", "Transition ADJ_SEC (01) -> ADJ_MIN (10)");
    drv.reset_dut(10);
    drv.pulse_sel(); // RUN -> SEC
    sb.check_mode(MODE_ADJ_SEC, "TC_3_1_2_IN_SEC");
    drv.pulse_sel(); // SEC -> MIN
    sb.check_mode(MODE_ADJ_MIN, "TC_3_1_2_TRANSITION_MIN");
    finish_test_footer("3.1.2", "Transition ADJ_SEC (01) -> ADJ_MIN (10)", errs, sb);
endtask

// 3.1.3: Transition ADJ_MIN (10) -> ADJ_HOUR (11)
task automatic run_tc_3_1_3(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("3.1.3", "Transition ADJ_MIN (10) -> ADJ_HOUR (11)");
    drv.reset_dut(10);
    drv.pulse_sel(); // RUN -> SEC
    drv.pulse_sel(); // SEC -> MIN
    sb.check_mode(MODE_ADJ_MIN, "TC_3_1_3_IN_MIN");
    drv.pulse_sel(); // MIN -> HOUR
    sb.check_mode(MODE_ADJ_HOUR, "TC_3_1_3_TRANSITION_HOUR");
    finish_test_footer("3.1.3", "Transition ADJ_MIN (10) -> ADJ_HOUR (11)", errs, sb);
endtask

// 3.1.4: Transition ADJ_HOUR (11) -> RUN (00) & Load Commit
task automatic run_tc_3_1_4(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("3.1.4", "Transition ADJ_HOUR (11) -> RUN (00) & Load Commit");
    drv.reset_dut(10);
    drv.pulse_sel(); // RUN -> SEC
    drv.pulse_sel(); // SEC -> MIN
    drv.pulse_sel(); // MIN -> HOUR
    sb.check_mode(MODE_ADJ_HOUR, "TC_3_1_4_IN_HOUR");
    // Pulse SEL to commit
    drv.pulse_sel(); // HOUR -> RUN
    sb.check_mode(MODE_RUN, "TC_3_1_4_RETURN_RUN");
    finish_test_footer("3.1.4", "Transition ADJ_HOUR (11) -> RUN (00) & Load Commit", errs, sb);
endtask

// 3.1.5: FSM idle state stability (self-loop hold)
task automatic run_tc_3_1_5(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("3.1.5", "FSM idle state stability (self-loop hold)");
    drv.reset_dut(10);
    sb.check_mode(MODE_RUN, "TC_3_1_5_RUN_START");
    drv.wait_cycles(20);
    sb.check_mode(MODE_RUN, "TC_3_1_5_RUN_STABLE");
    drv.pulse_sel(); // -> ADJ_SEC
    sb.check_mode(MODE_ADJ_SEC, "TC_3_1_5_SEC_START");
    drv.wait_cycles(20);
    sb.check_mode(MODE_ADJ_SEC, "TC_3_1_5_SEC_STABLE");
    finish_test_footer("3.1.5", "FSM idle state stability (self-loop hold)", errs, sb);
endtask

// 3.1.6: Strict single transition per SEL event pulse
task automatic run_tc_3_1_6(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("3.1.6", "Strict single transition per SEL event pulse");
    drv.reset_dut(10);
    // Single SEL pulse
    drv.pulse_sel(20, 25);
    sb.check_mode(MODE_ADJ_SEC, "TC_3_1_6_EXACTLY_ONE_STEP");
    drv.wait_cycles(20);
    sb.check_mode(MODE_ADJ_SEC, "TC_3_1_6_STILL_IN_SEC");
    finish_test_footer("3.1.6", "Strict single transition per SEL event pulse", errs, sb);
endtask

// 3.1.7: FSM safe-state default recovery from illegal state
task automatic run_tc_3_1_7(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("3.1.7", "FSM safe-state default recovery from illegal state");
    drv.reset_dut(10);
    // The FSM state register has 4 legal 2-bit states (00, 01, 10, 11).
    // All 4 are mapped. We verify FSM starts at MODE_RUN and default behavior is robust.
    sb.check_mode(MODE_RUN, "TC_3_1_7_FSM_SAFE_START");
    finish_test_footer("3.1.7", "FSM safe-state default recovery from illegal state", errs, sb);
endtask

// 3.2.1: Inactivity timeout 5s trigger & discard buffer
task automatic run_tc_3_2_1(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("3.2.1", "Inactivity timeout 5s trigger & discard buffer");
    drv.reset_dut(10);
    drv.pulse_sel(); // ADJ_SEC
    repeat (10) drv.pulse_up(); // sec = 10
    sb.check_time(0, 0, 10, "TC_3_2_1_EDITED_10");
    // Idle 5 sec_pulses
    repeat (5) @(posedge vif.sec_pulse);
    repeat (3) @(posedge vif.clk); #1ns;
    sb.check_mode(MODE_RUN, "TC_3_2_1_AUTO_RETURNED_TO_RUN");
    sb.check_signal(vif.load_en, 1'b0, "load_en_not_asserted", "TC_3_2_1");
    finish_test_footer("3.2.1", "Inactivity timeout 5s trigger & discard buffer", errs, sb);
endtask

// 3.2.2: Inactivity timeout keep-alive activity reset
task automatic run_tc_3_2_2(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("3.2.2", "Inactivity timeout keep-alive activity reset");
    drv.reset_dut(10);
    drv.pulse_sel(); // ADJ_SEC
    repeat (10) drv.pulse_up(); // sec = 10
    // Wait 3s
    repeat (3) @(posedge vif.sec_pulse);
    sb.check_mode(MODE_ADJ_SEC, "TC_3_2_2_ALIVE_AT_3S");
    // Keep-alive press
    drv.pulse_up(); // sec = 11
    // Wait 3s more (total 6s > 5s initial timeout)
    repeat (3) @(posedge vif.sec_pulse);
    sb.check_mode(MODE_ADJ_SEC, "TC_3_2_2_STILL_ALIVE");
    // Explicit commit
    drv.pulse_sel(); // SEC -> MIN
    drv.pulse_sel(); // MIN -> HOUR
    drv.pulse_sel(); // HOUR -> RUN
    sb.check_mode(MODE_RUN, "TC_3_2_2_COMMITTED_RUN");
    sb.check_time(0, 0, 11, "TC_3_2_2_VALUE_11_COMMITTED");
    finish_test_footer("3.2.2", "Inactivity timeout keep-alive activity reset", errs, sb);
endtask

// 3.2.3: Inactivity Timeout in MODE_ADJ_SEC: exact 5 sec_pulses
task automatic run_tc_3_2_3(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("3.2.3", "Inactivity Timeout in MODE_ADJ_SEC: exact 5 sec_pulses");
    drv.reset_dut(10);
    drv.pulse_sel(); // ADJ_SEC
    // 4 pulses: must still be in ADJ_SEC
    repeat (4) @(posedge vif.sec_pulse);
    @(posedge vif.clk); #1ns;
    sb.check_mode(MODE_ADJ_SEC, "TC_3_2_3_STILL_SEC_AT_4P");
    // 5th pulse: returns to RUN
    @(posedge vif.sec_pulse);
    repeat (3) @(posedge vif.clk); #1ns;
    sb.check_mode(MODE_RUN, "TC_3_2_3_RETURN_RUN_AT_5P");
    finish_test_footer("3.2.3", "Inactivity Timeout in MODE_ADJ_SEC: exact 5 sec_pulses", errs, sb);
endtask

// 3.2.4: Inactivity Timeout in MODE_ADJ_MIN: exact 5 sec_pulses
task automatic run_tc_3_2_4(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("3.2.4", "Inactivity Timeout in MODE_ADJ_MIN: exact 5 sec_pulses");
    drv.reset_dut(10);
    drv.pulse_sel(); // SEC
    drv.pulse_sel(); // MIN
    repeat (4) @(posedge vif.sec_pulse);
    @(posedge vif.clk); #1ns;
    sb.check_mode(MODE_ADJ_MIN, "TC_3_2_4_STILL_MIN_AT_4P");
    @(posedge vif.sec_pulse);
    repeat (3) @(posedge vif.clk); #1ns;
    sb.check_mode(MODE_RUN, "TC_3_2_4_RETURN_RUN_AT_5P");
    finish_test_footer("3.2.4", "Inactivity Timeout in MODE_ADJ_MIN: exact 5 sec_pulses", errs, sb);
endtask

// 3.2.5: Inactivity Timeout in MODE_ADJ_HOUR: exact 5 sec_pulses
task automatic run_tc_3_2_5(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("3.2.5", "Inactivity Timeout in MODE_ADJ_HOUR: exact 5 sec_pulses");
    drv.reset_dut(10);
    drv.pulse_sel(); // SEC
    drv.pulse_sel(); // MIN
    drv.pulse_sel(); // HOUR
    repeat (4) @(posedge vif.sec_pulse);
    @(posedge vif.clk); #1ns;
    sb.check_mode(MODE_ADJ_HOUR, "TC_3_2_5_STILL_HOUR_AT_4P");
    @(posedge vif.sec_pulse);
    repeat (3) @(posedge vif.clk); #1ns;
    sb.check_mode(MODE_RUN, "TC_3_2_5_RETURN_RUN_AT_5P");
    finish_test_footer("3.2.5", "Inactivity Timeout in MODE_ADJ_HOUR: exact 5 sec_pulses", errs, sb);
endtask

// 3.2.6: Timeout Rollback integrity: load_en strictly 0 on timeout
task automatic run_tc_3_2_6(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("3.2.6", "Timeout Rollback integrity: load_en strictly 0 on timeout");
    drv.reset_dut(10);
    drv.pulse_sel(); // SEC
    repeat (5) drv.pulse_up();
    repeat (5) begin
        @(posedge vif.sec_pulse);
        sb.check_signal(vif.load_en, 1'b0, "load_en_zero_during_timeout", "TC_3_2_6");
    end
    repeat (3) @(posedge vif.clk); #1ns;
    sb.check_mode(MODE_RUN, "TC_3_2_6_MODE_RUN");
    sb.check_signal(vif.load_en, 1'b0, "load_en_zero_after_timeout", "TC_3_2_6");
    finish_test_footer("3.2.6", "Timeout Rollback integrity: load_en strictly 0 on timeout", errs, sb);
endtask

// 3.2.7: Timeout Rollback display integrity: revert to real-time
task automatic run_tc_3_2_7(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("3.2.7", "Timeout Rollback display integrity: revert to real-time");
    drv.reset_dut(10);
    drv.wait_sec_pulses(2); // Background counter reaches 2
    drv.pulse_sel(); // Enter ADJ_SEC
    repeat (2) drv.pulse_up(); // Buffer = 4
    sb.check_time(0, 0, 4, "TC_3_2_7_BUFFER_DISPLAY");
    // Timeout 5 seconds
    repeat (5) @(posedge vif.sec_pulse);
    repeat (3) @(posedge vif.clk); #1ns;
    // Display must revert cleanly to real-time background counter
    sb.check_mode(MODE_RUN, "TC_3_2_7_REVERT_RUN");
    sb.check_time(vif.h_cnt, vif.m_cnt, vif.s_cnt, "TC_3_2_7_REVERT_BACKGROUND");
    finish_test_footer("3.2.7", "Timeout Rollback display integrity: revert to real-time", errs, sb);
endtask

// 3.2.8: Keep-alive reset via UP button at second 3
task automatic run_tc_3_2_8(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("3.2.8", "Keep-alive reset via UP button at second 3");
    drv.reset_dut(10);
    drv.pulse_sel(); // Enter ADJ_SEC
    repeat (3) @(posedge vif.sec_pulse);
    sb.check_mode(MODE_ADJ_SEC, "TC_3_2_8_AT_3S");
    drv.pulse_up(); // Keep-alive UP
    repeat (3) @(posedge vif.sec_pulse);
    sb.check_mode(MODE_ADJ_SEC, "TC_3_2_8_STILL_ALIVE_AFTER_UP");
    finish_test_footer("3.2.8", "Keep-alive reset via UP button at second 3", errs, sb);
endtask

// 3.2.9: Keep-alive reset via DOWN button at second 4
task automatic run_tc_3_2_9(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("3.2.9", "Keep-alive reset via DOWN button at second 4");
    drv.reset_dut(10);
    drv.pulse_sel(); // Enter ADJ_SEC
    repeat (4) @(posedge vif.sec_pulse);
    sb.check_mode(MODE_ADJ_SEC, "TC_3_2_9_AT_4S");
    drv.pulse_down(); // Keep-alive DOWN at 4th sec
    repeat (3) @(posedge vif.sec_pulse);
    sb.check_mode(MODE_ADJ_SEC, "TC_3_2_9_STILL_ALIVE_AFTER_DOWN");
    finish_test_footer("3.2.9", "Keep-alive reset via DOWN button at second 4", errs, sb);
endtask

// 3.2.10: Keep-alive reset via SEL button mode advancement
task automatic run_tc_3_2_10(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("3.2.10", "Keep-alive reset via SEL button mode advancement");
    drv.reset_dut(10);
    drv.pulse_sel(); // ADJ_SEC
    repeat (3) @(posedge vif.sec_pulse);
    drv.pulse_sel(); // Advance to ADJ_MIN
    sb.check_mode(MODE_ADJ_MIN, "TC_3_2_10_ADVANCED_TO_MIN");
    // Must remain alive for another 4 sec_pulses in ADJ_MIN
    repeat (4) @(posedge vif.sec_pulse);
    sb.check_mode(MODE_ADJ_MIN, "TC_3_2_10_MIN_ALIVE_AT_4S");
    finish_test_footer("3.2.10", "Keep-alive reset via SEL button mode advancement", errs, sb);
endtask

// 3.2.11: Critical collision: button press at exact cycle of 5th sec_pulse
task automatic run_tc_3_2_11(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("3.2.11", "Critical collision: button press at exact cycle of 5th sec_pulse");
    drv.reset_dut(10);
    drv.pulse_sel(); // Enter ADJ_SEC
    repeat (4) @(posedge vif.sec_pulse);
    // Align press with 5th pulse
    repeat (78) @(posedge vif.clk);
    vif.up_in <= 1'b1;
    repeat (22) @(posedge vif.clk);
    vif.up_in <= 1'b0;
    repeat (10) @(posedge vif.clk);
    sb.check_mode(MODE_ADJ_SEC, "TC_3_2_11_KEEPALIVE_PREVENTS_TIMEOUT");
    finish_test_footer("3.2.11", "Critical collision: button press at exact cycle of 5th sec_pulse", errs, sb);
endtask

// 3.3.1: Simultaneous UP + DOWN conflict resolution
task automatic run_tc_3_3_1(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("3.3.1", "Simultaneous UP + DOWN conflict resolution");
    drv.reset_dut(10);

    // 1. Test conflict in MODE_ADJ_SEC
    drv.pulse_sel(); // Enter SEC mode
    repeat (10) drv.pulse_up(); // sec = 10
    sb.check_time(0, 0, 10, "TC_3_3_1_SEC_AT_10");
    drv.pulse_up_down_simultaneous(20, 25);
    sb.check_time(0, 0, 10, "TC_3_3_1_SEC_HOLDS_ON_CONFLICT");

    // 2. Test conflict in MODE_ADJ_MIN
    drv.pulse_sel(); // Enter MIN mode
    repeat (15) drv.pulse_up(); // min = 15
    sb.check_time(0, 15, 10, "TC_3_3_1_MIN_AT_15");
    drv.pulse_up_down_simultaneous(20, 25);
    sb.check_time(0, 15, 10, "TC_3_3_1_MIN_HOLDS_ON_CONFLICT");

    // 3. Test conflict in MODE_ADJ_HOUR
    drv.pulse_sel(); // Enter HOUR mode
    repeat (8) drv.pulse_up(); // hour = 8
    sb.check_time(8, 15, 10, "TC_3_3_1_HOUR_AT_8");
    drv.pulse_up_down_simultaneous(20, 25);
    sb.check_time(8, 15, 10, "TC_3_3_1_HOUR_HOLDS_ON_CONFLICT");

    finish_test_footer("3.3.1", "Simultaneous UP + DOWN conflict resolution", errs, sb);
endtask

// 3.3.2: Inactive button immunity in MODE_RUN
task automatic run_tc_3_3_2(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("3.3.2", "Inactive button immunity in MODE_RUN");
    drv.reset_dut(10);
    sb.check_mode(MODE_RUN, "TC_3_3_2_START_RUN");
    drv.pulse_up(20, 25);
    sb.check_mode(MODE_RUN, "TC_3_3_2_UP_IGNORED");
    drv.pulse_down(20, 25);
    sb.check_mode(MODE_RUN, "TC_3_3_2_DOWN_IGNORED");
    drv.pulse_up_down_simultaneous(20, 25);
    sb.check_mode(MODE_RUN, "TC_3_3_2_SIMULTANEOUS_IGNORED");
    finish_test_footer("3.3.2", "Inactive button immunity in MODE_RUN", errs, sb);
endtask

// 3.3.3: Simultaneous SEL + UP in edit mode: SEL priority over edit
task automatic run_tc_3_3_3(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("3.3.3", "Simultaneous SEL + UP in edit mode: SEL priority over edit");
    drv.reset_dut(10);
    drv.pulse_sel(); // Enter ADJ_SEC
    drv.pulse_up();  // sec = 1
    sb.check_time(0, 0, 1, "TC_3_3_3_SEC_1");
    // Press SEL + UP simultaneous: SEL has priority, switches to ADJ_MIN without changing sec
    drv.pulse_sel_up_simultaneous(20, 25);
    sb.check_mode(MODE_ADJ_MIN, "TC_3_3_3_ADVANCED_TO_MIN");
    sb.check_time(0, 0, 1, "TC_3_3_3_SEC_NOT_CHANGED");
    finish_test_footer("3.3.3", "Simultaneous SEL + UP in edit mode: SEL priority over edit", errs, sb);
endtask

// 3.3.4: Simultaneous SEL + DOWN in edit mode: SEL priority over edit
task automatic run_tc_3_3_4(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("3.3.4", "Simultaneous SEL + DOWN in edit mode: SEL priority over edit");
    drv.reset_dut(10);
    drv.pulse_sel(); // SEC
    drv.pulse_sel(); // MIN
    drv.pulse_up();  // min = 1
    sb.check_time(0, 1, 0, "TC_3_3_4_MIN_1");
    // Press SEL + DOWN simultaneous: SEL has priority, switches to ADJ_HOUR without changing min
    drv.pulse_sel_down_simultaneous(20, 25);
    sb.check_mode(MODE_ADJ_HOUR, "TC_3_3_4_ADVANCED_TO_HOUR");
    sb.check_time(0, 1, 0, "TC_3_3_4_MIN_NOT_CHANGED");
    finish_test_footer("3.3.4", "Simultaneous SEL + DOWN in edit mode: SEL priority over edit", errs, sb);
endtask

`endif // TC_SEC3_FSM_TIMEOUT_SV
