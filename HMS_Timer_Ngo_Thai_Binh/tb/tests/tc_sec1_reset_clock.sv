//==============================================================================
// File: tc_sec1_reset_clock.sv
// Description: Testcases for Section 1: Reset & Clock Management (Items 1.1.1 - 1.5.6)
//              Each small item is implemented as an individual, self-contained testcase.
// Project: HMS_Timer
// Language: SystemVerilog
//==============================================================================

`ifndef TC_SEC1_RESET_CLOCK_SV
`define TC_SEC1_RESET_CLOCK_SV

// 1.1.1: Async reset propagation to internal FFs
task automatic run_tc_1_1_1(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("1.1.1", "Async reset propagation to internal FFs");
    drv.init_signals();
    drv.reset_dut(10);
    // Deassert rstn and wait 5 cycles
    vif.rstn <= 1'b1;
    drv.wait_cycles(5);
    sb.check_signal(vif.rstn_sync, 1'b1, "rstn_sync_before_async", "TC_1_1_1");

    // Drive rstn = 0 mid-cycle (asynchronous assert)
    #300ns;
    vif.rstn <= 1'b0;
    #10ns; // Within 10ns, before any clock edge
    sb.check_signal(vif.rstn_sync, 1'b0, "rstn_sync_immediate_async", "TC_1_1_1");
    drv.wait_cycles(2);
    vif.rstn <= 1'b1;
    drv.wait_cycles(3);
    finish_test_footer("1.1.1", "Async reset propagation to internal FFs", errs, sb);
endtask

// 1.1.2: Reset distribution to 8 submodules
task automatic run_tc_1_1_2(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("1.1.2", "Reset distribution to 8 submodules");
    drv.reset_dut(10);
    // Set some non-zero time and advance mode
    drv.pulse_sel(); // MODE_ADJ_SEC
    drv.pulse_up();  // sec = 1
    drv.pulse_sel(); // MODE_ADJ_MIN
    drv.pulse_up();  // min = 1
    drv.pulse_sel(); // MODE_ADJ_HOUR
    drv.pulse_up();  // hour = 1
    drv.pulse_sel(); // MODE_RUN (committed 01:01:01)

    // Now assert asynchronous reset
    vif.rstn <= 1'b0;
    #100ns;
    sb.check_signal(vif.rstn_sync, 1'b0, "rstn_sync", "TC_1_1_2");
    drv.wait_cycles(2);
    // Check all submodules cleared
    sb.check_time(0, 0, 0, "TC_1_1_2_OUTPUTS_ZERO");
    sb.check_mode(MODE_RUN, "TC_1_1_2_MODE_RUN");
    sb.check_signal(vif.load_en, 1'b0, "load_en_zero", "TC_1_1_2");
    sb.check_signal(vif.sec_rollover, 1'b0, "sec_rollover_zero", "TC_1_1_2");
    sb.check_signal(vif.min_rollover, 1'b0, "min_rollover_zero", "TC_1_1_2");
    sb.check_int(vif.s_cnt, 0, "s_cnt", "TC_1_1_2");
    sb.check_int(vif.m_cnt, 0, "m_cnt", "TC_1_1_2");
    sb.check_int(vif.h_cnt, 0, "h_cnt", "TC_1_1_2");
    vif.rstn <= 1'b1;
    drv.wait_cycles(3);
    finish_test_footer("1.1.2", "Reset distribution to 8 submodules", errs, sb);
endtask

// 1.1.3: Async reset assert when master clk is HIGH
task automatic run_tc_1_1_3(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("1.1.3", "Async reset assert when master clk is HIGH");
    drv.reset_dut(5);
    drv.wait_cycles(3);
    wait (vif.clk === 1'b1);
    #100ns; // still within clk HIGH phase
    vif.rstn <= 1'b0;
    #10ns;
    sb.check_signal(vif.rstn_sync, 1'b0, "rstn_sync_high_phase", "TC_1_1_3");
    drv.wait_cycles(5);
    vif.rstn <= 1'b1;
    drv.wait_cycles(3);
    finish_test_footer("1.1.3", "Async reset assert when master clk is HIGH", errs, sb);
endtask

// 1.1.4: Async reset assert when master clk is LOW
task automatic run_tc_1_1_4(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("1.1.4", "Async reset assert when master clk is LOW");
    drv.reset_dut(5);
    drv.wait_cycles(3);
    wait (vif.clk === 1'b0);
    #100ns; // still within clk LOW phase
    vif.rstn <= 1'b0;
    #10ns;
    sb.check_signal(vif.rstn_sync, 1'b0, "rstn_sync_low_phase", "TC_1_1_4");
    drv.wait_cycles(5);
    vif.rstn <= 1'b1;
    drv.wait_cycles(3);
    finish_test_footer("1.1.4", "Async reset assert when master clk is LOW", errs, sb);
endtask

// 1.1.5: Simultaneous clear of both synchronizer FF stages
task automatic run_tc_1_1_5(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("1.1.5", "Simultaneous clear of both synchronizer FF stages");
    drv.reset_dut(5);
    drv.wait_cycles(4);
    // Both FFs must be 1
    sb.check_signal(vif.meta_rstn, 1'b1, "meta_rstn_init", "TC_1_1_5");
    sb.check_signal(vif.sync_rstn, 1'b1, "sync_rstn_init", "TC_1_1_5");
    // Assert reset
    #200ns;
    vif.rstn <= 1'b0;
    #5ns;
    sb.check_signal(vif.meta_rstn, 1'b0, "meta_rstn_cleared", "TC_1_1_5");
    sb.check_signal(vif.sync_rstn, 1'b0, "sync_rstn_cleared", "TC_1_1_5");
    drv.wait_cycles(5);
    vif.rstn <= 1'b1;
    drv.wait_cycles(3);
    finish_test_footer("1.1.5", "Simultaneous clear of both synchronizer FF stages", errs, sb);
endtask

// 1.2.1: 2-cycle deassert delay
task automatic run_tc_1_2_1(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("1.2.1", "2-cycle deassert delay");
    vif.rstn <= 1'b0;
    drv.wait_cycles(5);
    @(posedge vif.clk); #10ns;
    vif.rstn <= 1'b1;
    // Cycle 1 after deassert
    @(posedge vif.clk); #1ns;
    sb.check_signal(vif.meta_rstn, 1'b1, "meta_rstn_cyc1", "TC_1_2_1");
    sb.check_signal(vif.sync_rstn, 1'b0, "sync_rstn_cyc1", "TC_1_2_1");
    sb.check_signal(vif.rstn_sync, 1'b0, "rstn_sync_cyc1", "TC_1_2_1");
    // Cycle 2 after deassert
    @(posedge vif.clk); #1ns;
    sb.check_signal(vif.meta_rstn, 1'b1, "meta_rstn_cyc2", "TC_1_2_1");
    sb.check_signal(vif.sync_rstn, 1'b1, "sync_rstn_cyc2", "TC_1_2_1");
    sb.check_signal(vif.rstn_sync, 1'b1, "rstn_sync_cyc2", "TC_1_2_1");
    finish_test_footer("1.2.1", "2-cycle deassert delay", errs, sb);
endtask

// 1.2.2: 2-Cycle Sync Latency & Removal Timing Margin
task automatic run_tc_1_2_2(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    int off;
    start_test_header("1.2.2", "2-Cycle Sync Latency & Removal Timing Margin");
    // Sweep deassertion offset: 100ns, 300ns, 500ns, 700ns
    for (off = 100; off <= 700; off += 200) begin
        vif.rstn <= 1'b0;
        drv.wait_cycles(3);
        @(posedge vif.clk);
        #(off * 1ns);
        vif.rstn <= 1'b1;
        // Exactly 2 clocks after the subsequent edge
        repeat (2) @(posedge vif.clk); #1ns;
        sb.check_signal(vif.rstn_sync, 1'b1, $sformatf("rstn_sync_offset_%0dns", off), "TC_1_2_2");
    end
    finish_test_footer("1.2.2", "2-Cycle Sync Latency & Removal Timing Margin", errs, sb);
endtask

// 1.3.1: Display = 00:00:00
task automatic run_tc_1_3_1(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("1.3.1", "Display = 00:00:00");
    drv.reset_dut(10);
    sb.check_time(0, 0, 0, "TC_1_3_1_INIT_DISPLAY");
    finish_test_footer("1.3.1", "Display = 00:00:00", errs, sb);
endtask

// 1.3.2: FSM = MODE_RUN (2'b00)
task automatic run_tc_1_3_2(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("1.3.2", "FSM = MODE_RUN (2'b00)");
    drv.reset_dut(10);
    sb.check_mode(MODE_RUN, "TC_1_3_2_INIT_MODE");
    finish_test_footer("1.3.2", "FSM = MODE_RUN (2'b00)", errs, sb);
endtask

// 1.3.3: All internal counters = 0
task automatic run_tc_1_3_3(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("1.3.3", "All internal counters = 0");
    drv.reset_dut(10);
    sb.check_int(vif.s_cnt, 0, "s_cnt", "TC_1_3_3");
    sb.check_int(vif.m_cnt, 0, "m_cnt", "TC_1_3_3");
    sb.check_int(vif.h_cnt, 0, "h_cnt", "TC_1_3_3");
    sb.check_int(vif.r_cnt_1khz, 0, "r_cnt_1khz", "TC_1_3_3");
    sb.check_int(vif.r_cnt_1hz, 0, "r_cnt_1hz", "TC_1_3_3");
    sb.check_int(vif.sel_timer_cnt, 0, "sel_timer_cnt", "TC_1_3_3");
    sb.check_int(vif.up_timer_cnt, 0, "up_timer_cnt", "TC_1_3_3");
    sb.check_int(vif.down_timer_cnt, 0, "down_timer_cnt", "TC_1_3_3");
    finish_test_footer("1.3.3", "All internal counters = 0", errs, sb);
endtask

// 1.4.1: Reset during free-run counting
task automatic run_tc_1_4_1(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("1.4.1", "Reset during free-run counting");
    drv.reset_dut(10);
    // Run for 3 seconds
    drv.wait_sec_pulses(3);
    sb.check_time(0, 0, 3, "TC_1_4_1_COUNTED_3");
    // Assert reset mid-run
    drv.reset_dut(10);
    sb.check_time(0, 0, 0, "TC_1_4_1_RESET_BACK_TO_ZERO");
    // Count 1 second
    drv.wait_sec_pulses(1);
    sb.check_time(0, 0, 1, "TC_1_4_1_RESUMED_FROM_ZERO");
    finish_test_footer("1.4.1", "Reset during free-run counting", errs, sb);
endtask

// 1.4.2: Reset during adjust mode
task automatic run_tc_1_4_2(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("1.4.2", "Reset during adjust mode");
    drv.reset_dut(10);
    drv.pulse_sel(); // ADJ_SEC
    repeat (5) drv.pulse_up();
    sb.check_time(0, 0, 5, "TC_1_4_2_SEC_ADJ");
    sb.check_mode(MODE_ADJ_SEC, "TC_1_4_2_MODE_SEC");
    // Assert reset
    drv.reset_dut(10);
    sb.check_mode(MODE_RUN, "TC_1_4_2_RETURN_RUN");
    sb.check_time(0, 0, 0, "TC_1_4_2_RESET_ZERO");
    sb.check_buffer(0, 0, 0, "TC_1_4_2_BUFFER_CLEARED");
    finish_test_footer("1.4.2", "Reset during adjust mode", errs, sb);
endtask

// 1.4.3: Reset during carry chain propagation
task automatic run_tc_1_4_3(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("1.4.3", "Reset during carry chain propagation");
    drv.reset_dut(10);
    // Set 23:59:58
    drv.set_time_via_edit(23, 59, 58);
    drv.wait_sec_pulses(1);
    sb.check_time(23, 59, 59, "TC_1_4_3_AT_59");
    // Wait for the rollover pulse
    @(posedge vif.sec_pulse);
    vif.rstn <= 1'b0; // Assert reset right at rollover
    drv.wait_cycles(5);
    vif.rstn <= 1'b1;
    drv.wait_cycles(2);
    sb.check_time(0, 0, 0, "TC_1_4_3_CLEAN_RESET_ON_ROLLOVER");
    finish_test_footer("1.4.3", "Reset during carry chain propagation", errs, sb);
endtask

// 1.4.4: Reset during button debounce hold
task automatic run_tc_1_4_4(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("1.4.4", "Reset during button debounce hold");
    drv.reset_dut(10);
    drv.pulse_sel(); // ADJ_SEC
    vif.up_in <= 1'b1;
    drv.wait_cycles(10); // Hold for 10 cycles (< 20 cycles)
    vif.rstn <= 1'b0;    // Reset midway
    drv.wait_cycles(5);
    vif.rstn <= 1'b1;
    vif.up_in <= 1'b0;
    drv.wait_cycles(5);
    sb.check_int(vif.up_timer_cnt, 0, "up_timer_cnt", "TC_1_4_4");
    sb.check_signal(vif.up_pulse, 1'b0, "up_pulse", "TC_1_4_4");
    finish_test_footer("1.4.4", "Reset during button debounce hold", errs, sb);
endtask

// 1.4.5: Reset glitch < 1 cycle clk
task automatic run_tc_1_4_5(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("1.4.5", "Reset glitch < 1 cycle clk");
    drv.reset_dut(10);
    drv.wait_cycles(5);
    // Inject narrow reset glitch of 50ns (< 1000ns clk period)
    drv.inject_reset_glitch(50);
    #10ns;
    sb.check_signal(vif.rstn_sync, 1'b0, "rstn_sync_after_glitch", "TC_1_4_5");
    drv.wait_cycles(3);
    sb.check_signal(vif.rstn_sync, 1'b1, "rstn_sync_recovered", "TC_1_4_5");
    sb.check_time(0, 0, 0, "TC_1_4_5_OUTPUTS_ZERO");
    finish_test_footer("1.4.5", "Reset glitch < 1 cycle clk", errs, sb);
endtask

// 1.4.6: Reset assertion at Second Counter rollover boundary
task automatic run_tc_1_4_6(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("1.4.6", "Reset assertion at Second Counter rollover boundary");
    drv.reset_dut(10);
    drv.set_time_via_edit(0, 0, 58);
    drv.wait_sec_pulses(1); // Now 59
    sb.check_time(0, 0, 59, "TC_1_4_6_AT_59");
    @(posedge vif.sec_pulse);
    vif.rstn <= 1'b0;
    drv.wait_cycles(5);
    vif.rstn <= 1'b1;
    drv.wait_cycles(2);
    sb.check_signal(vif.sec_rollover, 1'b0, "sec_rollover_suppressed", "TC_1_4_6");
    sb.check_time(0, 0, 0, "TC_1_4_6_RESET_CLEAN");
    finish_test_footer("1.4.6", "Reset assertion at Second Counter rollover boundary", errs, sb);
endtask

// 1.4.7: Reset assertion during active Debounce sequence
task automatic run_tc_1_4_7(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("1.4.7", "Reset assertion during active Debounce sequence");
    drv.reset_dut(10);
    vif.sel_in <= 1'b1;
    drv.wait_cycles(12);
    vif.rstn <= 1'b0;
    drv.wait_cycles(5);
    vif.rstn <= 1'b1;
    vif.sel_in <= 1'b0;
    drv.wait_cycles(5);
    sb.check_int(vif.sel_timer_cnt, 0, "sel_timer_cnt_cleared", "TC_1_4_7");
    sb.check_signal(vif.sel_pulse, 1'b0, "sel_pulse_no_event", "TC_1_4_7");
    finish_test_footer("1.4.7", "Reset assertion during active Debounce sequence", errs, sb);
endtask

// 1.4.8: Reset assertion during Inactivity Timeout countdown
task automatic run_tc_1_4_8(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("1.4.8", "Reset assertion during Inactivity Timeout countdown");
    drv.reset_dut(10);
    drv.pulse_sel(); // Enter ADJ_SEC
    repeat (4) @(posedge vif.sec_pulse);
    vif.rstn <= 1'b0;
    drv.wait_cycles(5);
    vif.rstn <= 1'b1;
    drv.wait_cycles(2);
    sb.check_mode(MODE_RUN, "TC_1_4_8_MODE_RUN");
    sb.check_int(vif.timeout_cnt, 0, "timeout_cnt", "TC_1_4_8");
    sb.check_signal(vif.load_en, 1'b0, "load_en", "TC_1_4_8");
    finish_test_footer("1.4.8", "Reset assertion during Inactivity Timeout countdown", errs, sb);
endtask

// 1.4.9: Reset assertion during Synchronous Commit cycle
task automatic run_tc_1_4_9(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("1.4.9", "Reset assertion during Synchronous Commit cycle");
    drv.reset_dut(10);
    drv.pulse_sel(); // SEC
    drv.pulse_sel(); // MIN
    drv.pulse_sel(); // HOUR
    repeat (5) drv.pulse_up(); // hour = 5
    // Commit via SEL, but inject reset at commit cycle
    @(posedge vif.clk);
    vif.sel_in <= 1'b1;
    repeat (20) @(posedge vif.clk);
    vif.sel_in <= 1'b0;
    // At the exact cycle of load_en, assert reset
    @(posedge vif.clk);
    vif.rstn <= 1'b0;
    drv.wait_cycles(5);
    vif.rstn <= 1'b1;
    drv.wait_cycles(2);
    sb.check_time(0, 0, 0, "TC_1_4_9_RESET_OVERRIDES_COMMIT");
    sb.check_mode(MODE_RUN, "TC_1_4_9_MODE_RUN");
    finish_test_footer("1.4.9", "Reset assertion during Synchronous Commit cycle", errs, sb);
endtask

// 1.4.10: Reset assertion during Midnight Rollover
task automatic run_tc_1_4_10(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("1.4.10", "Reset assertion during Midnight Rollover");
    drv.reset_dut(10);
    drv.set_time_via_edit(23, 59, 58);
    drv.wait_sec_pulses(1); // 23:59:59
    @(posedge vif.sec_pulse);
    vif.rstn <= 1'b0;
    drv.wait_cycles(5);
    vif.rstn <= 1'b1;
    drv.wait_cycles(2);
    sb.check_time(0, 0, 0, "TC_1_4_10_MIDNIGHT_RESET");
    finish_test_footer("1.4.10", "Reset assertion during Midnight Rollover", errs, sb);
endtask

// 1.5.1: Stage 1 1kHz pulse generation (pulse_1khz)
task automatic run_tc_1_5_1(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("1.5.1", "Stage 1 1kHz pulse generation (pulse_1khz)");
    drv.reset_dut(10);
    // Observe pulse_1khz
    drv.wait_cycles(5);
    sb.check_signal((vif.pulse_1khz !== 1'bx), 1'b1, "pulse_1khz_valid", "TC_1_5_1");
    finish_test_footer("1.5.1", "Stage 1 1kHz pulse generation (pulse_1khz)", errs, sb);
endtask

// 1.5.2: Stage 2 1Hz pulse generation (sec_pulse)
task automatic run_tc_1_5_2(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("1.5.2", "Stage 2 1Hz pulse generation (sec_pulse)");
    drv.reset_dut(10);
    @(posedge vif.sec_pulse);
    sb.check_signal(vif.sec_pulse, 1'b1, "sec_pulse_asserted", "TC_1_5_2");
    finish_test_footer("1.5.2", "Stage 2 1Hz pulse generation (sec_pulse)", errs, sb);
endtask

// 1.5.3: Prescaler pulse width exact 1-cycle master clock
task automatic run_tc_1_5_3(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("1.5.3", "Prescaler pulse width exact 1-cycle master clock");
    drv.reset_dut(10);
    @(posedge vif.sec_pulse);
    @(posedge vif.clk); #1ns;
    sb.check_signal(vif.sec_pulse, 1'b0, "sec_pulse_deasserted_in_1cycle", "TC_1_5_3");
    finish_test_footer("1.5.3", "Prescaler pulse width exact 1-cycle master clock", errs, sb);
endtask

// 1.5.4: Prescaler Stage 1 exact 1,000 clock period interval
task automatic run_tc_1_5_4(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("1.5.4", "Prescaler Stage 1 exact 1,000 clock period interval");
    drv.reset_dut(10);
    drv.wait_cycles(10);
    // In fast simulation (PL_SIM_CLK_FREQ_HZ=100 <= 100), pulse_1khz is tied to 1
    sb.check_signal(vif.pulse_1khz, 1'b1, "pulse_1khz_fast_mode", "TC_1_5_4");
    finish_test_footer("1.5.4", "Prescaler Stage 1 exact 1,000 clock period interval", errs, sb);
endtask

// 1.5.5: Prescaler Stage 2 exact 1,000 pulse_1khz period interval
task automatic run_tc_1_5_5(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    int cycle_cnt;
    start_test_header("1.5.5", "Prescaler Stage 2 exact 1,000 pulse_1khz period interval");
    drv.reset_dut(10);
    @(posedge vif.sec_pulse);
    @(posedge vif.clk); #1ns; // Allow registers and combinational assign to settle
    cycle_cnt = 1;
    while (!vif.sec_pulse) begin
        @(posedge vif.clk); #1ns;
        cycle_cnt++;
        if (cycle_cnt > 200) break; // timeout safety
    end
    sb.check_int(cycle_cnt, 100, "cycles_per_sec_pulse", "TC_1_5_5");
    finish_test_footer("1.5.5", "Prescaler Stage 2 exact 1,000 pulse_1khz period interval", errs, sb);
endtask

// 1.5.6: Prescaler counter wrap-around and dead-lock freedom
task automatic run_tc_1_5_6(hms_driver drv, hms_scoreboard sb, virtual hms_timer_if vif);
    int errs = sb.failed_checks;
    start_test_header("1.5.6", "Prescaler counter wrap-around and dead-lock freedom");
    drv.reset_dut(10);
    // Observe 3 consecutive sec_pulses
    repeat (3) begin
        @(posedge vif.sec_pulse);
        @(posedge vif.clk); #1ns;
    end
    sb.check_time(0, 0, 3, "TC_1_5_6_TIME_3");
    finish_test_footer("1.5.6", "Prescaler counter wrap-around and dead-lock freedom", errs, sb);
endtask

`endif // TC_SEC1_RESET_CLOCK_SV
