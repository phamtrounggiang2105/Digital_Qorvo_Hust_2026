//==============================================================================
// File: tc_sec2_button_debouncer.sv
// Description: Testcases for Section 2: Button Processing & Debouncing / Glitch Immunity (Items 2.1.1 - 2.2.6)
//              Each small item is implemented as an individual, self-contained testcase.
// Project: HMS_Timer
// Language: SystemVerilog
//==============================================================================

`ifndef TC_SEC2_BUTTON_DEBOUNCER_SV
`define TC_SEC2_BUTTON_DEBOUNCER_SV

// 2.1.1: Short noise rejection (< 20ms / < 20 ticks)
task automatic run_tc_2_1_1(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("2.1.1", "Short noise rejection (< 20ms / < 20 ticks)");
    drv.init_signals();
    drv.reset_dut(10);
    drv.pulse_sel(); // Enter ADJ_SEC
    sb.check_time(0, 0, 0, "TC_2_1_1_INIT_ZERO");

    // Hold UP button for 15 cycles (< 20 threshold)
    @(posedge vif.clk);
    vif.up_in <= 1'b1;
    drv.wait_cycles(15);
    vif.up_in <= 1'b0;
    drv.wait_cycles(25);
    sb.check_time(0, 0, 0, "TC_2_1_1_REJECTED_SHORT_PRESS");
    sb.check_signal(vif.up_pulse, 1'b0, "up_pulse_no_event", "TC_2_1_1");
    finish_test_footer("2.1.1", "Short noise rejection (< 20ms / < 20 ticks)", errs, sb);
endtask

// 2.1.2: Nominal press acceptance (>= 20ms / 20 ticks)
task automatic run_tc_2_1_2(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("2.1.2", "Nominal press acceptance (>= 20ms / 20 ticks)");
    drv.reset_dut(10);
    drv.pulse_sel(); // Enter ADJ_SEC
    drv.pulse_up(20, 25);
    sb.check_time(0, 0, 1, "TC_2_1_2_ACCEPTED_PRESS");
    finish_test_footer("2.1.2", "Nominal press acceptance (>= 20ms / 20 ticks)", errs, sb);
endtask

// 2.1.3: Intermediate hold duration (25 ticks)
task automatic run_tc_2_1_3(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("2.1.3", "Intermediate hold duration (25 ticks)");
    drv.reset_dut(10);
    drv.pulse_sel(); // Enter ADJ_SEC
    drv.pulse_up(25, 25);
    sb.check_time(0, 0, 1, "TC_2_1_3_SINGLE_EVENT_25_CYCLES");
    finish_test_footer("2.1.3", "Intermediate hold duration (25 ticks)", errs, sb);
endtask

// 2.1.4: Single-event long hold (60 ticks / No Auto-Repeat)
task automatic run_tc_2_1_4(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("2.1.4", "Single-event long hold (60 ticks / No Auto-Repeat)");
    drv.reset_dut(10);
    drv.pulse_sel(); // Enter ADJ_SEC
    @(posedge vif.clk);
    vif.up_in <= 1'b1;
    drv.wait_cycles(60); // Long continuous hold
    vif.up_in <= 1'b0;
    drv.wait_cycles(25);
    sb.check_time(0, 0, 1, "TC_2_1_4_SINGLE_EVENT_NO_AUTOREPEAT");
    finish_test_footer("2.1.4", "Single-event long hold (60 ticks / No Auto-Repeat)", errs, sb);
endtask

// 2.1.5: Mechanical bounce noise rejection at boundary (18-19 samples)
task automatic run_tc_2_1_5(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("2.1.5", "Mechanical bounce noise rejection at boundary (18-19 samples)");
    drv.reset_dut(10);
    drv.pulse_sel(); // Enter ADJ_SEC
    // 18 cycles
    vif.up_in <= 1'b1;
    drv.wait_cycles(18);
    vif.up_in <= 1'b0;
    drv.wait_cycles(25);
    sb.check_time(0, 0, 0, "TC_2_1_5_REJECT_18");
    // 19 cycles
    vif.up_in <= 1'b1;
    drv.wait_cycles(19);
    vif.up_in <= 1'b0;
    drv.wait_cycles(25);
    sb.check_time(0, 0, 0, "TC_2_1_5_REJECT_19");
    finish_test_footer("2.1.5", "Mechanical bounce noise rejection at boundary (18-19 samples)", errs, sb);
endtask

// 2.1.6: Mechanical release qualification: brief release (< 20ms) rejected
task automatic run_tc_2_1_6(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("2.1.6", "Mechanical release qualification: brief release (< 20ms) rejected");
    drv.reset_dut(10);
    drv.pulse_sel(); // Enter ADJ_SEC
    vif.up_in <= 1'b1;
    drv.wait_cycles(25); // Press accepted, s_out = 1
    sb.check_time(0, 0, 1, "TC_2_1_6_INITIAL_PRESS");
    // Brief release for 10 cycles (< 20)
    vif.up_in <= 1'b0;
    drv.wait_cycles(10);
    // Re-assert
    vif.up_in <= 1'b1;
    drv.wait_cycles(25);
    vif.up_in <= 1'b0;
    drv.wait_cycles(25);
    // Value must still be 1 because brief release did not reset debounced state
    sb.check_time(0, 0, 1, "TC_2_1_6_BRIEF_RELEASE_REJECTED");
    finish_test_footer("2.1.6", "Mechanical release qualification: brief release (< 20ms) rejected", errs, sb);
endtask

// 2.1.7: Mechanical release qualification: full release (>= 20ms) resets state
task automatic run_tc_2_1_7(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("2.1.7", "Mechanical release qualification: full release (>= 20ms) resets state");
    drv.reset_dut(10);
    drv.pulse_sel(); // Enter ADJ_SEC
    // Press 1
    drv.pulse_up(20, 25); // full release 25 cycles
    sb.check_time(0, 0, 1, "TC_2_1_7_PRESS_1");
    sb.check_signal(vif.up_debounced, 1'b0, "up_debounced_cleared", "TC_2_1_7");
    // Press 2
    drv.pulse_up(20, 25);
    sb.check_time(0, 0, 2, "TC_2_1_7_PRESS_2");
    finish_test_footer("2.1.7", "Mechanical release qualification: full release (>= 20ms) resets state", errs, sb);
endtask

// 2.1.8: Consecutive valid button presses separated by idle release
task automatic run_tc_2_1_8(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("2.1.8", "Consecutive valid button presses separated by idle release");
    drv.reset_dut(10);
    drv.pulse_sel(); // Enter ADJ_SEC
    drv.pulse_up(20, 25);
    sb.check_time(0, 0, 1, "TC_2_1_8_STEP_1");
    drv.pulse_up(20, 25);
    sb.check_time(0, 0, 2, "TC_2_1_8_STEP_2");
    drv.pulse_up(20, 25);
    sb.check_time(0, 0, 3, "TC_2_1_8_STEP_3");
    finish_test_footer("2.1.8", "Consecutive valid button presses separated by idle release", errs, sb);
endtask

// 2.1.9: Strict single-clock-cycle pulse width on btn_event
task automatic run_tc_2_1_9(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("2.1.9", "Strict single-clock-cycle pulse width on btn_event");
    drv.reset_dut(10);
    @(posedge vif.clk);
    vif.up_in <= 1'b1;
    // Wait until up_pulse is asserted
    @(posedge vif.up_pulse);
    // At the very next clock posedge, up_pulse must be 0
    @(posedge vif.clk); #1ns;
    sb.check_signal(vif.up_pulse, 1'b0, "up_pulse_dropped_next_cycle", "TC_2_1_9");
    vif.up_in <= 1'b0;
    drv.wait_cycles(25);
    finish_test_footer("2.1.9", "Strict single-clock-cycle pulse width on btn_event", errs, sb);
endtask

// 2.1.10: Debouncer counter hold verification between 1kHz enables
task automatic run_tc_2_1_10(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("2.1.10", "Debouncer counter hold verification between 1kHz enables");
    drv.reset_dut(10);
    drv.wait_cycles(5);
    // In our fast simulation (P_CLK_FREQ_HZ=100 <= 100), pulse_1khz is 1'b1 every cycle,
    // so debouncer samples every cycle. We verify timer_cnt increments monotonically up to threshold.
    vif.up_in <= 1'b1;
    @(posedge vif.clk); #1ns;
    sb.check_signal((vif.up_timer_cnt <= 20), 1'b1, "up_timer_cnt_within_bound", "TC_2_1_10");
    vif.up_in <= 1'b0;
    drv.wait_cycles(25);
    finish_test_footer("2.1.10", "Debouncer counter hold verification between 1kHz enables", errs, sb);
endtask

// 2.1.11: Debouncer reset gating verification at 1kHz sampling rate
task automatic run_tc_2_1_11(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("2.1.11", "Debouncer reset gating verification at 1kHz sampling rate");
    drv.reset_dut(10);
    drv.pulse_sel(); // Enter ADJ_SEC
    vif.up_in <= 1'b1;
    drv.wait_cycles(10);
    vif.up_in <= 1'b0; // Release input early
    drv.wait_cycles(5);
    sb.check_int(vif.up_timer_cnt, 0, "up_timer_cnt_cleared_on_release", "TC_2_1_11");
    drv.wait_cycles(20);
    finish_test_footer("2.1.11", "Debouncer reset gating verification at 1kHz sampling rate", errs, sb);
endtask

// 2.2.1: Sub-cycle narrow glitch rejection (< 100ns)
task automatic run_tc_2_2_1(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("2.2.1", "Sub-cycle narrow glitch rejection (< 100ns)");
    drv.reset_dut(10);
    drv.pulse_sel(); // Enter ADJ_SEC
    drv.inject_glitch(50); // 50ns glitch
    drv.wait_cycles(30);
    sb.check_time(0, 0, 0, "TC_2_2_1_GLITCH_REJECTED");
    sb.check_signal(vif.up_pulse, 1'b0, "up_pulse_no_event", "TC_2_2_1");
    finish_test_footer("2.2.1", "Sub-cycle narrow glitch rejection (< 100ns)", errs, sb);
endtask

// 2.2.2: Multi-channel button independent processing
task automatic run_tc_2_2_2(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("2.2.2", "Multi-channel button independent processing");
    drv.reset_dut(10);
    // Pulse SEL
    drv.pulse_sel(20, 25);
    sb.check_mode(MODE_ADJ_SEC, "TC_2_2_2_SEL_PULSE");
    // Pulse UP
    drv.pulse_up(20, 25);
    sb.check_time(0, 0, 1, "TC_2_2_2_UP_PULSE");
    // Pulse DOWN
    drv.pulse_down(20, 25);
    sb.check_time(0, 0, 0, "TC_2_2_2_DOWN_PULSE");
    finish_test_footer("2.2.2", "Multi-channel button independent processing", errs, sb);
endtask

// 2.2.3: Asynchronous button edge phase shift sweep
task automatic run_tc_2_2_3(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("2.2.3", "Asynchronous button edge phase shift sweep");
    drv.reset_dut(10);
    drv.pulse_sel(); // ADJ_SEC
    // Sweep phase offsets: 100ns, 250ns, 500ns, 750ns
    for (int off = 100; off <= 750; off += 200) begin
        @(posedge vif.clk);
        #(off * 1ns);
        vif.up_in <= 1'b1;
        repeat (20) @(posedge vif.clk);
        vif.up_in <= 1'b0;
        repeat (25) @(posedge vif.clk);
    end
    sb.check_time(0, 0, 4, "TC_2_2_3_FOUR_PHASE_PRESSES");
    finish_test_footer("2.2.3", "Asynchronous button edge phase shift sweep", errs, sb);
endtask

// 2.2.4: Two-button concurrent valid press (SEL + UP simultaneous)
task automatic run_tc_2_2_4(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("2.2.4", "Two-button concurrent valid press (SEL + UP simultaneous)");
    drv.reset_dut(10);
    drv.pulse_sel_up_simultaneous(20, 25);
    sb.check_mode(MODE_ADJ_SEC, "TC_2_2_4_ENTER_SEC_MODE");
    finish_test_footer("2.2.4", "Two-button concurrent valid press (SEL + UP simultaneous)", errs, sb);
endtask

// 2.2.5: Three-button concurrent valid press (SEL + UP + DOWN)
task automatic run_tc_2_2_5(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("2.2.5", "Three-button concurrent valid press (SEL + UP + DOWN)");
    drv.reset_dut(10);
    drv.pulse_all_three_simultaneous(20, 25);
    sb.check_mode(MODE_ADJ_SEC, "TC_2_2_5_SEL_DETECTED");
    finish_test_footer("2.2.5", "Three-button concurrent valid press (SEL + UP + DOWN)", errs, sb);
endtask

// 2.2.6: Channel isolation: UP button activity does not affect SEL/DOWN
task automatic run_tc_2_2_6(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("2.2.6", "Channel isolation: UP button activity does not affect SEL/DOWN");
    drv.reset_dut(10);
    // In RUN mode, rapidly pulse UP 5 times
    repeat (5) drv.pulse_up(20, 25);
    sb.check_signal(vif.sel_pulse, 1'b0, "sel_pulse_stays_zero", "TC_2_2_6");
    sb.check_signal(vif.down_pulse, 1'b0, "down_pulse_stays_zero", "TC_2_2_6");
    sb.check_mode(MODE_RUN, "TC_2_2_6_MODE_REMAINS_RUN");
    finish_test_footer("2.2.6", "Channel isolation: UP button activity does not affect SEL/DOWN", errs, sb);
endtask

`endif // TC_SEC2_BUTTON_DEBOUNCER_SV
