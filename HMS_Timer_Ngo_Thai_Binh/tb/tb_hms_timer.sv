//==============================================================================
// File: tb_hms_timer.sv
// Module: tb_hms_timer (Top Verification Testbench)
// Description: Comprehensive SystemVerilog Testbench for verifying the
//              HMS_Timer IP Core against all specification requirements.
//              Features:
//              - Automated Test Cases (Reset, Prescaler, FSM, Cascade, Adjustments,
//                Wrap-Arounds, Isolation, Conflict Resolution, Glitch, Day Wrap,
//                Button Debounce 20ms & Auto-Repeat, 5s Inactivity Timeout & Rollback,
//                5s Inactivity Timeout Keepalive)
//              - Golden Reference Model & Cycle-accurate Scoreboard
//              - SystemVerilog Concurrent Assertions (SVA) Checkers
//              - Functional Coverage Metric Tracking
// Project: HMS_Timer
// Language: SystemVerilog
//==============================================================================

`timescale 1ns / 1ps

import hms_timer_types_pkg::*;

`include "hms_driver.sv"
`include "hms_scoreboard.sv"
`include "hms_coverage.sv"

module tb_hms_timer;

    // Clock frequency and period configuration
    // 1 MHz Clock -> Period = 1000 ns (1 us)
    localparam realtime PL_CLK_PERIOD = 1000ns;

    // Simulation Prescaler setting: 100 cycles per 1 second pulse
    localparam int PL_SIM_CLK_FREQ_HZ   = 100;

    // Clock generator
    logic clk;
    initial begin
        clk = 1'b0;
        forever #(PL_CLK_PERIOD / 2.0) clk = ~clk;
    end

    // Interface instantiation
    hms_timer_if vif (
        .clk(clk)
    );

    // DUT Instantiation with fast prescaler parameter for testbench execution
    hms_timer #(
        .P_CLK_FREQ_HZ        (PL_SIM_CLK_FREQ_HZ),
        .P_PULSE_1KHZ_FREQ_HZ (100),
        .P_DEBOUNCE_PULSES    (20), // 20 pulses of sampling clock
        .P_TIMEOUT_SEC        (5)
    ) dut (
        .clk       (vif.clk),
        .rstn      (vif.rstn),
        .sel_in    (vif.sel_in),
        .up_in     (vif.up_in),
        .down_in   (vif.down_in),
        .h_out     (vif.h_out),
        .m_out     (vif.m_out),
        .s_out     (vif.s_out)
    );

    // Bind internal probes to interface for verification visibility
    assign vif.rstn_sync      = dut.rstn_sync;
    assign vif.pulse_1khz     = dut.pulse_1khz;
    assign vif.sel_pulse      = dut.sel_pulse;
    assign vif.up_pulse       = dut.up_pulse;
    assign vif.down_pulse     = dut.down_pulse;
    assign vif.sec_pulse      = dut.sec_pulse;
    assign vif.adj_mode       = dut.adj_mode;
    assign vif.load_en        = dut.load_en;
    assign vif.sec_rollover   = dut.sec_rollover;
    assign vif.min_rollover   = dut.min_rollover;
    assign vif.adj_sec        = dut.adj_sec;
    assign vif.adj_min        = dut.adj_min;
    assign vif.adj_hour       = dut.adj_hour;
    assign vif.s_cnt          = dut.s_cnt;
    assign vif.m_cnt          = dut.m_cnt;
    assign vif.h_cnt          = dut.h_cnt;

    // Testbench OOP Components
    hms_driver     driver;
    hms_scoreboard scoreboard;
    hms_coverage   coverage;

    //==========================================================================
    // Test Tasks & Execution Sequences
    //==========================================================================

    // TC1: Power-on Reset and Recovery Verification
    task run_tc1_reset_recovery();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 1: Power-on Reset & Recovery Verification <<<");
        $display("--------------------------------------------------------------------------------");
        driver.init_signals();
        driver.reset_dut(10);
        scoreboard.check_time(0, 0, 0, "TC1_RESET");
        scoreboard.check_mode(MODE_RUN, "TC1_RESET_MODE");
    endtask

    // TC2: Prescaler & Normal Cascade Real-Time Counting
    task run_tc2_normal_counting();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 2: Prescaler & Real-Time Normal Cascade Counting <<<");
        $display("--------------------------------------------------------------------------------");
        driver.reset_dut(10);
        log_info("Observing natural counting progression across seconds and minutes...");
        
        // Wait for 10 simulated seconds
        for (int i = 1; i <= 10; i++) begin
            @(posedge vif.sec_pulse);
            @(posedge vif.clk); #1ns;
            scoreboard.check_time(0, 0, i, $sformatf("TC2_SEC_%0d", i));
        end
    endtask

    // TC3: Mode Controller FSM Navigation
    task run_tc3_fsm_navigation();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 3: Mode Controller FSM Navigation (Circular Loop) <<<");
        $display("--------------------------------------------------------------------------------");
        driver.reset_dut(10);
        
        // Mode 00 -> Mode 01 (ADJ_SEC)
        driver.pulse_sel();
        scoreboard.check_mode(MODE_ADJ_SEC, "TC3_TRANSITION_TO_SEC");

        // Mode 01 -> Mode 10 (ADJ_MIN)
        driver.pulse_sel();
        scoreboard.check_mode(MODE_ADJ_MIN, "TC3_TRANSITION_TO_MIN");

        // Mode 10 -> Mode 11 (ADJ_HOUR)
        driver.pulse_sel();
        scoreboard.check_mode(MODE_ADJ_HOUR, "TC3_TRANSITION_TO_HOUR");

        // Mode 11 -> Mode 00 (RUN)
        driver.pulse_sel();
        scoreboard.check_mode(MODE_RUN, "TC3_TRANSITION_TO_RUN");
    endtask

    // TC4: Second Adjustment (Increment, Decrement, Wrap-Around)
    task run_tc4_second_adjustment();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 4: Seconds Adjustment (Up / Down / Wrap-Around) <<<");
        $display("--------------------------------------------------------------------------------");
        driver.reset_dut(10);
        
        // Enter ADJ_SEC mode: RUN (00) -> ADJ_SEC (01)
        driver.pulse_sel();
        scoreboard.check_mode(MODE_ADJ_SEC, "TC4_ENTER_SEC_ADJ");
        scoreboard.check_time(0, 0, 0, "TC4_SEC_INIT_ZERO");

        // Test Up button increments
        log_info("Testing Second Increment (Up)...");
        driver.pulse_up();
        scoreboard.check_time(0, 0, 1, "TC4_SEC_UP_1");
        driver.pulse_up();
        scoreboard.check_time(0, 0, 2, "TC4_SEC_UP_2");

        // Test Down button decrements
        log_info("Testing Second Decrement (Down)...");
        driver.pulse_down();
        scoreboard.check_time(0, 0, 1, "TC4_SEC_DOWN_1");
        driver.pulse_down();
        scoreboard.check_time(0, 0, 0, "TC4_SEC_DOWN_2");

        // Down from 0 -> Wrap to 59
        log_info("Testing Wrap-down (0 -> 59)...");
        driver.pulse_down();
        scoreboard.check_time(0, 0, 59, "TC4_SEC_WRAP_DOWN_59");

        // Up from 59 -> Wrap to 0
        log_info("Testing Wrap-up (59 -> 0)...");
        driver.pulse_up();
        scoreboard.check_time(0, 0, 0, "TC4_SEC_WRAP_UP_0");
    endtask

    // TC5: Minute Adjustment (Increment, Decrement, Wrap-Around)
    task run_tc5_minute_adjustment();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 5: Minutes Adjustment (Up / Down / Wrap-Around) <<<");
        $display("--------------------------------------------------------------------------------");
        driver.reset_dut(10);
        
        // Navigate to ADJ_MIN: RUN -> SEC -> MIN
        driver.pulse_sel(); // RUN -> SEC
        driver.pulse_sel(); // SEC -> MIN
        scoreboard.check_mode(MODE_ADJ_MIN, "TC5_ENTER_MIN_ADJ");
        scoreboard.check_time(0, 0, 0, "TC5_MIN_INIT_ZERO");

        // Increment Minute
        log_info("Testing Minute Increment (Up)...");
        driver.pulse_up();
        scoreboard.check_time(0, 1, 0, "TC5_MIN_UP_1");
        driver.pulse_up();
        scoreboard.check_time(0, 2, 0, "TC5_MIN_UP_2");

        // Decrement Minute
        log_info("Testing Minute Decrement (Down)...");
        driver.pulse_down();
        scoreboard.check_time(0, 1, 0, "TC5_MIN_DOWN_1");
        driver.pulse_down();
        scoreboard.check_time(0, 0, 0, "TC5_MIN_DOWN_2");

        // Decrement from 0 -> Wrap to 59
        log_info("Testing Minute Wrap-down (0 -> 59)...");
        driver.pulse_down();
        scoreboard.check_time(0, 59, 0, "TC5_MIN_WRAP_DOWN_59");

        // Increment from 59 -> Wrap to 0
        log_info("Testing Minute Wrap-up (59 -> 0)...");
        driver.pulse_up();
        scoreboard.check_time(0, 0, 0, "TC5_MIN_WRAP_UP_0");
    endtask

    // TC6: Hour Adjustment (Increment, Decrement, Wrap-Around)
    task run_tc6_hour_adjustment();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 6: Hours Adjustment (Up / Down / Wrap-Around) <<<");
        $display("--------------------------------------------------------------------------------");
        driver.reset_dut(10);
        
        // Navigate to ADJ_HOUR: RUN -> SEC -> MIN -> HOUR
        driver.pulse_sel(); // RUN -> SEC
        driver.pulse_sel(); // SEC -> MIN
        driver.pulse_sel(); // MIN -> HOUR
        scoreboard.check_mode(MODE_ADJ_HOUR, "TC6_ENTER_HOUR_ADJ");
        scoreboard.check_time(0, 0, 0, "TC6_HOUR_INIT_ZERO");

        // Increment Hour
        log_info("Testing Hour Increment (Up)...");
        driver.pulse_up();
        scoreboard.check_time(1, 0, 0, "TC6_HOUR_UP_1");
        driver.pulse_up();
        scoreboard.check_time(2, 0, 0, "TC6_HOUR_UP_2");

        // Decrement Hour
        log_info("Testing Hour Decrement (Down)...");
        driver.pulse_down();
        scoreboard.check_time(1, 0, 0, "TC6_HOUR_DOWN_1");
        driver.pulse_down();
        scoreboard.check_time(0, 0, 0, "TC6_HOUR_DOWN_2");

        // Decrement from 0 -> Wrap to 23
        log_info("Testing Hour Wrap-down (0 -> 23)...");
        driver.pulse_down();
        scoreboard.check_time(23, 0, 0, "TC6_HOUR_WRAP_DOWN_23");

        // Increment from 23 -> Wrap to 0
        log_info("Testing Hour Wrap-up (23 -> 0)...");
        driver.pulse_up();
        scoreboard.check_time(0, 0, 0, "TC6_HOUR_WRAP_UP_0");
    endtask

    // TC7: Rollover Isolation Verification during Adjustment
    task run_tc7_rollover_isolation();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 7: Rollover Isolation & Gating Verification <<<");
        $display("--------------------------------------------------------------------------------");
        driver.reset_dut(10);
        
        // Enter ADJ_SEC mode: RUN -> ADJ_SEC
        driver.pulse_sel();
        scoreboard.check_mode(MODE_ADJ_SEC, "TC7_SEC_MODE");

        // Set second to 59
        driver.pulse_down(); // 0 -> 59
        scoreboard.check_time(0, 0, 59, "TC7_SEC_SET_59");

        // Pulse Up: 59 -> 0. Check that Minute DOES NOT increment (remains 0)
        driver.pulse_up();
        scoreboard.check_time(0, 0, 0, "TC7_SEC_WRAPPED_MIN_ISOLATED");

        // Switch to ADJ_MIN mode
        driver.pulse_sel(); // SEC -> MIN
        scoreboard.check_mode(MODE_ADJ_MIN, "TC7_MIN_MODE");

        // Set minute to 59
        driver.pulse_down(); // 0 -> 59
        scoreboard.check_time(0, 59, 0, "TC7_MIN_SET_59");

        // Pulse Up: 59 -> 0. Check that Hour DOES NOT increment (remains 0)
        driver.pulse_up();
        scoreboard.check_time(0, 0, 0, "TC7_MIN_WRAPPED_HOUR_ISOLATED");
    endtask

    // TC8: Simultaneous Up & Down Button Press Conflict
    task run_tc8_simultaneous_press();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 8: Simultaneous Up & Down Button Conflict Resolution <<<");
        $display("--------------------------------------------------------------------------------");
        driver.reset_dut(10);
        
        // Enter ADJ_MIN mode: RUN -> SEC -> MIN
        driver.pulse_sel();
        driver.pulse_sel();
        scoreboard.check_mode(MODE_ADJ_MIN, "TC8_MIN_MODE");

        // In ADJ_MIN mode, set minute to 15
        repeat (15) driver.pulse_up();
        scoreboard.check_time(0, 15, 0, "TC8_MIN_AT_15");

        // Assert both UP and DOWN at the exact same clock cycles
        log_info("Pressing UP and DOWN simultaneously...");
        driver.pulse_up_down_simultaneous();
        
        // Value must hold strictly at 15
        scoreboard.check_time(0, 15, 0, "TC8_HOLD_ON_SIMULTANEOUS_PRESS");
    endtask

    // TC9: Asynchronous Narrow Glitch & Metastability Rejection
    task run_tc9_async_glitch_test();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 9: Asynchronous Narrow Glitch Rejection Test <<<");
        $display("--------------------------------------------------------------------------------");
        
        // Inject narrow glitch (< 100ns, system clock is 1000ns)
        log_info("Injecting sub-cycle asynchronous glitch to up_in...");
        driver.inject_glitch(50);
        driver.wait_cycles(5);

        // Verify glitch was safely ignored or sampled without corrupted state
        scoreboard.check_mode(MODE_ADJ_MIN, "TC9_MODE_INTACT");
    endtask

    // TC10: Real-Time Rollovers (Minute increment, Hour increment, Midnight cascade)
    task run_tc10_midnight_cascade();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 10: Real-Time Rollovers (Minute, Hour & Midnight Cascade) <<<");
        $display("--------------------------------------------------------------------------------");
        
        // ---------------------------------------------------------------------
        // Part A: Normal Minute Increment (sec_rollover=1, min_rollover=0)
        // Set time to 10:15:58 -> count to 10:15:59 -> 10:16:00
        // ---------------------------------------------------------------------
        log_info("Part A: Verifying normal minute increment (10:15:58 -> 10:16:00)...");
        driver.reset_dut(10);
        driver.pulse_sel(); // RUN -> SEC
        driver.pulse_down(); // 59
        driver.pulse_down(); // 58
        driver.pulse_sel(); // SEC -> MIN
        repeat (15) driver.pulse_up(); // 15
        driver.pulse_sel(); // MIN -> HOUR
        repeat (10) driver.pulse_up(); // 10
        driver.pulse_sel(); // HOUR -> RUN
        scoreboard.check_time(10, 15, 58, "TC10_PART_A_SET_10_15_58");

        @(posedge vif.sec_pulse);
        @(posedge vif.clk); #1ns;
        scoreboard.check_time(10, 15, 59, "TC10_PART_A_COUNT_10_15_59");

        @(posedge vif.sec_pulse);
        @(posedge vif.clk); #1ns;
        scoreboard.check_time(10, 16, 0, "TC10_PART_A_MINUTE_INC_10_16_00");

        // ---------------------------------------------------------------------
        // Part B: Normal Hour Increment (sec_rollover=1, min_rollover=1)
        // Set time to 10:59:58 -> count to 10:59:59 -> 11:00:00
        // ---------------------------------------------------------------------
        log_info("Part B: Verifying normal hour increment (10:59:58 -> 11:00:00)...");
        driver.reset_dut(10);
        driver.pulse_sel(); // RUN -> SEC
        driver.pulse_down(); // 59
        driver.pulse_down(); // 58
        driver.pulse_sel(); // SEC -> MIN
        driver.pulse_down(); // 59
        driver.pulse_sel(); // MIN -> HOUR
        repeat (10) driver.pulse_up(); // 10
        driver.pulse_sel(); // HOUR -> RUN
        scoreboard.check_time(10, 59, 58, "TC10_PART_B_SET_10_59_58");

        @(posedge vif.sec_pulse);
        @(posedge vif.clk); #1ns;
        scoreboard.check_time(10, 59, 59, "TC10_PART_B_COUNT_10_59_59");

        @(posedge vif.sec_pulse);
        @(posedge vif.clk); #1ns;
        scoreboard.check_time(11, 0, 0, "TC10_PART_B_HOUR_INC_11_00_00");

        // ---------------------------------------------------------------------
        // Part C: 23:59:59 to 00:00:00 Midnight Cascade Rollover
        // ---------------------------------------------------------------------
        log_info("Part C: Verifying midnight rollover (23:59:58 -> 00:00:00)...");
        driver.reset_dut(10);
        
        // 1. Navigate to ADJ_SEC mode: RUN -> SEC
        driver.pulse_sel(); // RUN -> SEC
        scoreboard.check_mode(MODE_ADJ_SEC, "TC10_SEC_MODE");

        // Set second to 58: 0 -> 59 -> 58 via wrap-down
        driver.pulse_down(); // 0 -> 59
        driver.pulse_down(); // 59 -> 58
        scoreboard.check_time(0, 0, 58, "TC10_SEC_SET_58");

        // 2. Navigate to ADJ_MIN mode: SEC -> MIN
        driver.pulse_sel(); // SEC -> MIN
        scoreboard.check_mode(MODE_ADJ_MIN, "TC10_MIN_MODE");

        // Set minute to 59: 0 -> 59 via wrap-down
        driver.pulse_down();
        scoreboard.check_time(0, 59, 58, "TC10_MIN_SET_59");

        // 3. Navigate to ADJ_HOUR mode: MIN -> HOUR
        driver.pulse_sel(); // MIN -> HOUR
        scoreboard.check_mode(MODE_ADJ_HOUR, "TC10_HOUR_MODE");

        // Set hour to 23: 0 -> 23 via wrap-down
        driver.pulse_down();
        scoreboard.check_time(23, 59, 58, "TC10_TIME_SET_23_59_58");

        // 4. Switch to MODE_RUN for real-time natural counting: HOUR -> RUN
        driver.pulse_sel(); // HOUR -> RUN
        scoreboard.check_mode(MODE_RUN, "TC10_ENTER_RUN_MODE");

        // Wait 1 second pulse: 23:59:58 -> 23:59:59
        log_info("Waiting for real-time pulse to reach 23:59:59...");
        @(posedge vif.sec_pulse);
        @(posedge vif.clk); #1ns;
        scoreboard.check_time(23, 59, 59, "TC10_COUNT_23_59_59");

        // Wait 1 second pulse: 23:59:59 -> 00:00:00 (Midnight Cascade Rollover!)
        log_info("Waiting for midnight rollover to 00:00:00...");
        @(posedge vif.sec_pulse);
        @(posedge vif.clk); #1ns;
        scoreboard.check_time(0, 0, 0, "TC10_MIDNIGHT_ROLLOVER_SUCCESS");
    endtask

    // TC11: Exhaustive Cross Stimulus Coverage
    task run_tc11_exhaustive_cross_stimulus();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 11: Exhaustive Cross Stimulus & Inactive Button Immunity <<<");
        $display("--------------------------------------------------------------------------------");
        driver.reset_dut(10);
        
        // 1. In MODE_RUN, test UP, DOWN, and UP+DOWN presses (all should be ignored)
        scoreboard.check_mode(MODE_RUN, "TC11_RUN_MODE");
        driver.pulse_up();
        driver.pulse_down();
        driver.pulse_up_down_simultaneous();
        scoreboard.check_mode(MODE_RUN, "TC11_RUN_IMMUNITY_MODE");

        // 2. In MODE_ADJ_SEC, test UP+DOWN simultaneous
        driver.reset_dut(10);
        driver.pulse_sel();
        scoreboard.check_mode(MODE_ADJ_SEC, "TC11_SEC_MODE");
        driver.pulse_up_down_simultaneous();
        scoreboard.check_time(0, 0, 0, "TC11_SEC_SIMULTANEOUS");

        // 3. In MODE_ADJ_HOUR, test UP+DOWN simultaneous
        driver.pulse_sel(); // SEC -> MIN
        driver.pulse_sel(); // MIN -> HOUR
        scoreboard.check_mode(MODE_ADJ_HOUR, "TC11_HOUR_MODE");
        driver.pulse_up_down_simultaneous();
        scoreboard.check_time(0, 0, 0, "TC11_HOUR_SIMULTANEOUS");

        // Return to RUN mode
        driver.pulse_sel();
        scoreboard.check_mode(MODE_RUN, "TC11_RETURN_RUN");
    endtask

    // TC12: Button Debouncer 20ms Hold & Single-Event Verification
    task run_tc12_button_debouncer_and_autorepeat();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 12: Button Debounce 20ms Hold & Single Event Verification <<<");
        $display("--------------------------------------------------------------------------------");
        driver.reset_dut(10);

        // Enter ADJ_SEC mode
        driver.pulse_sel();
        scoreboard.check_mode(MODE_ADJ_SEC, "TC12_ENTER_SEC_MODE");

        // 1. Hold UP button for 19 cycles (< 20 pulses threshold) -> Strictly ignored (Noise rejection)
        log_info("Testing button hold below debounce threshold (19 cycles < 20 cycles)...");
        @(posedge vif.clk);
        vif.up_in <= 1'b1;
        repeat (19) @(posedge vif.clk);
        vif.up_in <= 1'b0;
        driver.wait_cycles(25);
        scoreboard.check_time(0, 0, 0, "TC12_REJECT_SHORT_PRESS_BELOW_THRESHOLD");

        // 2. Hold UP button for 20 cycles (= nominal debounce time) -> Accepted, 1 pulse
        log_info("Testing button hold at nominal debounce time (20 cycles)...");
        driver.pulse_up(20, 25);
        scoreboard.check_time(0, 0, 1, "TC12_ACCEPT_NOMINAL_DEBOUNCE");

        // 3. Hold UP button for 25 cycles (< 40 cycles) -> Accepted, still 1 pulse
        log_info("Testing button hold between 1 and 2 debounce periods (25 cycles)...");
        @(posedge vif.clk);
        vif.up_in <= 1'b1;
        repeat (25) @(posedge vif.clk);
        vif.up_in <= 1'b0;
        driver.wait_cycles(25);
        scoreboard.check_time(0, 0, 2, "TC12_ACCEPT_INTERMEDIATE_HOLD");

        // 4. Hold UP button continuously (60 cycles -> exactly 1 event pulse, no auto-repeat)...
        log_info("Testing button held continuously (60 cycles -> single pulse, no auto-repeat)...");
        @(posedge vif.clk);
        vif.up_in <= 1'b1;
        repeat (60) @(posedge vif.clk);
        vif.up_in <= 1'b0;
        driver.wait_cycles(25);
        // Previous value was 2, plus 1 pulse = 3
        scoreboard.check_time(0, 0, 3, "TC12_SINGLE_EVENT_LONG_HOLD");

        // Return to RUN mode
        driver.pulse_sel(); // SEC -> MIN
        driver.pulse_sel(); // MIN -> HOUR
        driver.pulse_sel(); // HOUR -> RUN
        scoreboard.check_mode(MODE_RUN, "TC12_RETURN_RUN");
    endtask

    // TC13: 5s Inactivity Timeout & Automatic Rollback (Cancel Changes)
    task run_tc13_inactivity_timeout_rollback();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 13: 5s Inactivity Timeout & Automatic Rollback Verification <<<");
        $display("--------------------------------------------------------------------------------");
        
        // -------------------------------------------------------------
        // Sub-test 1: 5s Timeout in MODE_ADJ_SEC
        // -------------------------------------------------------------
        log_info("Sub-test 1: Verifying 5s Inactivity Timeout in MODE_ADJ_SEC...");
        driver.reset_dut(10);
        scoreboard.check_time(0, 0, 0, "TC13_SEC_INIT_TIME");
        driver.pulse_sel(); // RUN -> ADJ_SEC
        scoreboard.check_mode(MODE_ADJ_SEC, "TC13_ENTER_ADJ_SEC_1");
        repeat (10) driver.pulse_up();
        scoreboard.check_time(0, 0, 10, "TC13_SEC_EDITED_10");

        // Idle for 5 seconds without button presses
        repeat (5) @(posedge vif.sec_pulse);
        repeat (3) @(posedge vif.clk); #1ns;
        scoreboard.check_mode(MODE_RUN, "TC13_TIMEOUT_SEC_RETURN_TO_RUN");

        // -------------------------------------------------------------
        // Sub-test 2: 5s Timeout in MODE_ADJ_MIN
        // -------------------------------------------------------------
        log_info("Sub-test 2: Verifying 5s Inactivity Timeout in MODE_ADJ_MIN...");
        driver.reset_dut(10);
        driver.pulse_sel(); // RUN -> ADJ_SEC
        driver.pulse_sel(); // ADJ_SEC -> ADJ_MIN
        scoreboard.check_mode(MODE_ADJ_MIN, "TC13_ENTER_ADJ_MIN_2");
        repeat (10) driver.pulse_up();
        scoreboard.check_time(0, 10, 0, "TC13_MIN_EDITED_10");

        // Idle for 5 seconds without button presses
        repeat (5) @(posedge vif.sec_pulse);
        repeat (3) @(posedge vif.clk); #1ns;
        scoreboard.check_mode(MODE_RUN, "TC13_TIMEOUT_MIN_RETURN_TO_RUN");

        // -------------------------------------------------------------
        // Sub-test 3: 5s Timeout in MODE_ADJ_HOUR (Original Flow)
        // -------------------------------------------------------------
        log_info("Sub-test 3: Verifying 5s Inactivity Timeout in MODE_ADJ_HOUR...");
        driver.reset_dut(10);
        
        // Ensure starting at 00:00:00 in MODE_RUN
        scoreboard.check_time(0, 0, 0, "TC13_INIT_TIME");
        scoreboard.check_mode(MODE_RUN, "TC13_INIT_MODE");

        // Step 1: Enter ADJ_SEC mode (Snapshot captures 00:00:00)
        driver.pulse_sel();
        scoreboard.check_mode(MODE_ADJ_SEC, "TC13_ENTER_ADJ_SEC");

        // Step 2: Modify seconds to 25
        log_info("Modifying seconds to 25...");
        repeat (25) driver.pulse_up();
        scoreboard.check_time(0, 0, 25, "TC13_SEC_MODIFIED_TO_25");

        // Step 3: Switch to ADJ_MIN mode and modify minutes to 40
        driver.pulse_sel();
        scoreboard.check_mode(MODE_ADJ_MIN, "TC13_ENTER_ADJ_MIN");
        repeat (40) driver.pulse_up();
        scoreboard.check_time(0, 40, 25, "TC13_MIN_MODIFIED_TO_40");

        // Step 4: Switch to ADJ_HOUR mode and modify hours to 12
        driver.pulse_sel();
        scoreboard.check_mode(MODE_ADJ_HOUR, "TC13_ENTER_ADJ_HOUR");
        repeat (12) driver.pulse_up();
        scoreboard.check_time(12, 40, 25, "TC13_HOUR_MODIFIED_TO_12");

        // Step 5: Do NOT commit via SEL. Instead, stay idle for 5 seconds (5 sec_pulses)
        log_info("Idling without any button activity to trigger 5s Inactivity Timeout...");
        repeat (5) begin
            @(posedge vif.sec_pulse);
        end
        repeat (3) @(posedge vif.clk); #1ns;

        // Step 6: Verify FSM automatically returns to MODE_RUN and switches display back to background counter (41 seconds elapsed)
        scoreboard.check_mode(MODE_RUN, "TC13_AUTO_RETURNED_TO_RUN");
        scoreboard.check_time(0, 0, 41, "TC13_RESUME_BACKGROUND_TIME_ZERO_DRIFT");
    endtask

    // TC14: 5s Inactivity Timeout Keep-Alive Activity Reset
    task run_tc14_inactivity_keepalive();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 14: 5s Inactivity Timeout Keep-Alive Activity Reset <<<");
        $display("--------------------------------------------------------------------------------");
        driver.reset_dut(10);
        
        // Enter ADJ_SEC mode
        driver.pulse_sel();
        scoreboard.check_mode(MODE_ADJ_SEC, "TC14_ENTER_ADJ_SEC");

        // Modify seconds to 10
        repeat (10) driver.pulse_up();
        scoreboard.check_time(0, 0, 10, "TC14_SEC_SET_10");

        // Wait 3 seconds (< 5 seconds timeout)
        log_info("Waiting 3 seconds (< 5s timeout)...");
        repeat (3) @(posedge vif.sec_pulse);
        scoreboard.check_mode(MODE_ADJ_SEC, "TC14_STILL_IN_ADJ_SEC");

        // Press UP button to reset inactivity timer (Keep-Alive)
        log_info("Pressing UP button to reset inactivity timer...");
        driver.pulse_up();
        scoreboard.check_time(0, 0, 11, "TC14_SEC_SET_11");

        // Wait another 3 seconds (< 5s since last press)
        log_info("Waiting another 3 seconds (< 5s since last press)...");
        repeat (3) @(posedge vif.sec_pulse);
        scoreboard.check_mode(MODE_ADJ_SEC, "TC14_STILL_ALIVE_AFTER_KEEP_ALIVE");

        // Now explicitly commit by cycling through to MODE_RUN
        driver.pulse_sel(); // SEC -> MIN
        driver.pulse_sel(); // MIN -> HOUR
        driver.pulse_sel(); // HOUR -> RUN
        scoreboard.check_mode(MODE_RUN, "TC14_EXPLICIT_COMMIT_RUN");

        // Value must be retained at 00:00:11
        scoreboard.check_time(0, 0, 11, "TC14_VALUE_COMMITTED_SUCCESSFULLY");
    endtask

    // TC15: Reset Active Corners & Asynchronous Injection Verification
    task run_tc15_reset_corners();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 15: Reset Active Corners & Asynchronous Injection <<<");
        $display("--------------------------------------------------------------------------------");
        
        // 1. Async reset assert when clk is HIGH
        log_info("Sub-test 1: Async reset assert during master clk HIGH phase...");
        driver.async_reset_clk_high();
        scoreboard.check_time(0, 0, 0, "TC15_ASYNC_RST_CLK_HIGH_TIME");
        scoreboard.check_mode(MODE_RUN, "TC15_ASYNC_RST_CLK_HIGH_MODE");

        // 2. Async reset assert when clk is LOW
        log_info("Sub-test 2: Async reset assert during master clk LOW phase...");
        driver.async_reset_clk_low();
        scoreboard.check_time(0, 0, 0, "TC15_ASYNC_RST_CLK_LOW_TIME");
        scoreboard.check_mode(MODE_RUN, "TC15_ASYNC_RST_CLK_LOW_MODE");

        // 3. Reset assertion at Second Counter rollover boundary (s_cnt == 59, sec_pulse == 1)
        log_info("Sub-test 3: Reset at Second counter rollover boundary (59)...");
        driver.reset_dut(10);
        repeat (58) @(posedge vif.sec_pulse);
        @(posedge vif.sec_pulse); // At 59th second
        vif.rstn <= 1'b0; // Assert reset right at boundary
        repeat (5) @(posedge vif.clk);
        vif.rstn <= 1'b1;
        repeat (2) @(posedge vif.clk);
        scoreboard.check_time(0, 0, 0, "TC15_RESET_AT_SEC_59");

        // 4. Reset during active Debounce sequence (mid-count)
        log_info("Sub-test 4: Reset during active debounce counting...");
        vif.up_in <= 1'b1;
        repeat (10) @(posedge vif.clk); // Halfway (10 pulses)
        vif.rstn <= 1'b0; // Assert reset
        repeat (5) @(posedge vif.clk);
        vif.rstn <= 1'b1;
        vif.up_in <= 1'b0;
        repeat (2) @(posedge vif.clk);
        scoreboard.check_time(0, 0, 0, "TC15_RESET_DURING_DEBOUNCE");

        // 5. Reset during Inactivity Timeout countdown (at sec 4)
        log_info("Sub-test 5: Reset during Inactivity Timeout countdown...");
        driver.pulse_sel(); // Enter ADJ_SEC
        scoreboard.check_mode(MODE_ADJ_SEC, "TC15_ENTER_ADJ_SEC");
        repeat (4) @(posedge vif.sec_pulse); // 4 seconds elapsed
        vif.rstn <= 1'b0;
        repeat (5) @(posedge vif.clk);
        vif.rstn <= 1'b1;
        repeat (2) @(posedge vif.clk);
        scoreboard.check_mode(MODE_RUN, "TC15_RESET_DURING_TIMEOUT_MODE");
        scoreboard.check_time(0, 0, 0, "TC15_RESET_DURING_TIMEOUT_TIME");
    endtask

    // TC16: Prescaler Pulse Precision & Deadlock Freedom
    task run_tc16_prescaler_precision();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 16: Prescaler Pulse Precision & Deadlock Freedom <<<");
        $display("--------------------------------------------------------------------------------");
        driver.reset_dut(10);
        
        log_info("Observing 5 sec_pulses for pulse width compliance...");
        repeat (5) begin
            @(posedge vif.sec_pulse);
            @(posedge vif.clk); #1ns;
            assert (vif.sec_pulse === 1'b0) else $error("[FAIL] sec_pulse held for > 1 clock cycle!");
        end
        scoreboard.check_time(0, 0, 5, "TC16_PRESCALER_5S_CONTINUOUS");
    endtask

    // TC17: Debounce Corners, Release Qualification & SEL Priority
    task run_tc17_debounce_corners();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 17: Debounce Corners, Release Qualification & Priorities <<<");
        $display("--------------------------------------------------------------------------------");
        driver.reset_dut(10);

        // 1. Release qualification: Short release (< 20 pulses) is ignored
        log_info("Sub-test 1: Short release (< 20 pulses) ignored while held...");
        driver.set_mode(MODE_ADJ_SEC);
        vif.up_in <= 1'b1;
        repeat (25) @(posedge vif.clk); // Press accepted, s_out = 1
        vif.up_in <= 1'b0; // Release briefly
        repeat (10) @(posedge vif.clk); // 10 pulses (< 20)
        vif.up_in <= 1'b1; // Press again
        repeat (25) @(posedge vif.clk);
        vif.up_in <= 1'b0;
        repeat (25) @(posedge vif.clk); // Full release
        scoreboard.check_time(0, 0, 1, "TC17_SHORT_RELEASE_REJECTION");

        // 2. Full release (>= 20 pulses) enables next press
        log_info("Sub-test 2: Full release (>= 20 pulses) qualifies second press...");
        driver.pulse_up(25, 25);
        scoreboard.check_time(0, 0, 2, "TC17_FULL_RELEASE_SECOND_PRESS");

        // 3. SEL + UP simultaneous in edit mode: SEL priority over UP
        log_info("Sub-test 3: Simultaneous SEL + UP in edit mode (SEL priority)...");
        driver.pulse_sel_up_simultaneous(25, 25);
        scoreboard.check_mode(MODE_ADJ_MIN, "TC17_SEL_UP_PRIORITY_MODE");
        scoreboard.check_time(0, 0, 2, "TC17_SEL_UP_PRIORITY_VAL_SEC");

        // 4. SEL + DOWN simultaneous in edit mode: SEL priority over DOWN
        log_info("Sub-test 4: Simultaneous SEL + DOWN in edit mode (SEL priority)...");
        driver.pulse_sel_down_simultaneous(25, 25);
        scoreboard.check_mode(MODE_ADJ_HOUR, "TC17_SEL_DOWN_PRIORITY_MODE");
        scoreboard.check_time(0, 0, 2, "TC17_SEL_DOWN_PRIORITY_VAL_MIN");

        // 5. All three buttons simultaneous press
        log_info("Sub-test 5: Simultaneous all 3 buttons press...");
        driver.pulse_all_three_simultaneous(25, 25);
        scoreboard.check_mode(MODE_RUN, "TC17_ALL_THREE_PRIORITY_MODE");
    endtask

    // TC18: Wrap-Around Boundaries, Buffer Isolation & Snapshot
    task run_tc18_wrap_and_isolation();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 18: Wrap Boundaries, Buffer Isolation & Snapshot <<<");
        $display("--------------------------------------------------------------------------------");
        driver.reset_dut(10);

        // 1. Snapshot capture: run to 00:00:15, then enter ADJ_SEC
        log_info("Sub-test 1: Snapshot capture on entering ADJ_SEC...");
        repeat (15) @(posedge vif.sec_pulse);
        driver.pulse_sel(); // Enter ADJ_SEC
        scoreboard.check_mode(MODE_ADJ_SEC, "TC18_ENTER_ADJ_SEC");
        scoreboard.check_time(0, 0, 15, "TC18_SNAPSHOT_CAPTURED");

        // 2. Second underflow wrap: 15 down to 0, then 0 -> 59
        log_info("Sub-test 2: Second underflow wrap 00 -> 59...");
        repeat (15) driver.pulse_down();
        scoreboard.check_time(0, 0, 0, "TC18_SEC_ZERO");
        driver.pulse_down(); // 0 -> 59
        scoreboard.check_time(0, 0, 59, "TC18_SEC_UNDERFLOW_59");

        // 3. Buffer isolation: Minute and Hour must still be 0
        driver.pulse_sel(); // Enter ADJ_MIN
        scoreboard.check_mode(MODE_ADJ_MIN, "TC18_ENTER_ADJ_MIN");
        scoreboard.check_time(0, 0, 59, "TC18_MIN_ISOLATION_INITIAL");

        // 4. Minute underflow wrap: 00 -> 59
        log_info("Sub-test 3: Minute underflow wrap 00 -> 59...");
        driver.pulse_down();
        scoreboard.check_time(0, 59, 59, "TC18_MIN_UNDERFLOW_59");

        // 5. Hour overflow wrap: 00 -> 23 on DOWN, and 23 -> 00 on UP
        driver.pulse_sel(); // Enter ADJ_HOUR
        scoreboard.check_mode(MODE_ADJ_HOUR, "TC18_ENTER_ADJ_HOUR");
        scoreboard.check_time(0, 59, 59, "TC18_HOUR_ISOLATION_INITIAL");
        log_info("Sub-test 4: Hour underflow 00 -> 23 and overflow 23 -> 00...");
        driver.pulse_down(); // 0 -> 23
        scoreboard.check_time(23, 59, 59, "TC18_HOUR_UNDERFLOW_23");
        driver.pulse_up(); // 23 -> 0
        scoreboard.check_time(0, 59, 59, "TC18_HOUR_OVERFLOW_00");

        // 6. Data persistence across menu: change hour to 10 and commit
        repeat (10) driver.pulse_up();
        scoreboard.check_time(10, 59, 59, "TC18_HOUR_SET_10");
        @(posedge vif.sec_pulse);
        driver.pulse_sel(20, 10); // HOUR -> RUN (Commit)
        scoreboard.check_mode(MODE_RUN, "TC18_COMMIT_RUN");
        scoreboard.check_time(10, 59, 59, "TC18_COMMIT_ALL_FIELDS_COMMITTED");
    endtask

    // TC19: Synchronous Commit Collisions, Priority & Glitchless MUX
    task run_tc19_commit_collision_and_priority();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 19: Commit Collisions, Priority & Glitchless MUX <<<");
        $display("--------------------------------------------------------------------------------");
        driver.reset_dut(10);

        // 1. Commit load priority over sec_pulse
        log_info("Sub-test 1: Commit collision with sec_pulse...");
        driver.set_mode(MODE_ADJ_HOUR);
        repeat (5) driver.pulse_up(); // Hour = 5
        @(posedge vif.clk);
        wait (dut.u_clk_prescaler.r_cnt_1hz == 76);
        vif.sel_in <= 1'b1;
        repeat (25) @(posedge vif.clk);
        vif.sel_in <= 1'b0;
        repeat (25) @(posedge vif.clk);
        scoreboard.check_mode(MODE_RUN, "TC19_COMMIT_MODE_RUN");

        // 2. Counting resumption from committed value
        log_info("Sub-test 2: Counting resumption from committed value...");
        @(posedge vif.sec_pulse);
        @(posedge vif.clk); #1ns;
        scoreboard.check_time(5, 0, 1, "TC19_RESUMPTION_COUNTING");
    endtask

    // TC20: Timeout Corners & Collision with 5th sec_pulse
    task run_tc20_timeout_corners_and_collision();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 20: Timeout Corners & 5th sec_pulse Collision <<<");
        $display("--------------------------------------------------------------------------------");
        driver.reset_dut(10);

        // 1. Keep-alive via DOWN button at 4th second
        log_info("Sub-test 1: Keep-alive via DOWN button at 4th second...");
        driver.pulse_sel(); // Enter ADJ_SEC
        repeat (4) @(posedge vif.sec_pulse);
        scoreboard.check_mode(MODE_ADJ_SEC, "TC20_STILL_IN_ADJ_SEC_AT_4S");
        driver.pulse_down(); // DOWN keep-alive
        repeat (3) @(posedge vif.sec_pulse);
        scoreboard.check_mode(MODE_ADJ_SEC, "TC20_ALIVE_AFTER_DOWN_KEEPALIVE");

        // 2. Keep-alive via SEL button mode advance
        log_info("Sub-test 2: Keep-alive via SEL mode advance...");
        driver.pulse_sel(); // Advance to ADJ_MIN
        scoreboard.check_mode(MODE_ADJ_MIN, "TC20_ADVANCED_TO_ADJ_MIN");
        repeat (3) @(posedge vif.sec_pulse);
        scoreboard.check_mode(MODE_ADJ_MIN, "TC20_MIN_ALIVE_AT_3S");

        // 3. Collision: button press at exact cycle of 5th sec_pulse
        log_info("Sub-test 3: Button press collision at 5th sec_pulse (Keep-alive wins)...");
        @(posedge vif.sec_pulse); // 4th pulse
        repeat (78) @(posedge vif.clk); // Wait until 20 cycles before 5th pulse
        vif.up_in <= 1'b1;
        repeat (22) @(posedge vif.clk);
        vif.up_in <= 1'b0;
        repeat (10) @(posedge vif.clk);
        scoreboard.check_mode(MODE_ADJ_MIN, "TC20_KEEPALIVE_WINS_ON_COLLISION");

        // Natural timeout rollback
        log_info("Sub-test 4: Natural timeout rollback...");
        repeat (6) @(posedge vif.sec_pulse);
        scoreboard.check_mode(MODE_RUN, "TC20_TIMEOUT_NATURAL_EXIT_TO_RUN");
    endtask

    // TC21: End-to-End Complete Scenarios & Midnight Commit Cascade
    task run_tc21_e2e_scenarios();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 21: End-to-End Scenarios & Midnight Commit Cascade <<<");
        $display("--------------------------------------------------------------------------------");
        driver.reset_dut(10);

        // 1. Commit before midnight: set to 23:59:58, commit, verify cascade to 00:00:00
        log_info("Sub-test 1: E2E Commit 23:59:58 and cascade across midnight...");
        driver.pulse_sel(); // SEC
        repeat (58) driver.pulse_up();
        driver.pulse_sel(); // MIN
        repeat (59) driver.pulse_up();
        driver.pulse_sel(); // HOUR
        repeat (23) driver.pulse_up();
        @(posedge vif.sec_pulse);
        driver.pulse_sel(20, 10); // Commit to RUN
        scoreboard.check_mode(MODE_RUN, "TC21_MIDNIGHT_COMMIT_RUN");
        scoreboard.check_time(23, 59, 58, "TC21_COMMITTED_23_59_58");

        // Let it tick 1s -> 23:59:59
        @(posedge vif.sec_pulse);
        @(posedge vif.clk); #1ns;
        scoreboard.check_time(23, 59, 59, "TC21_MIDNIGHT_MINUS_ONE");

        // Let it tick 1s -> 00:00:00 (Midnight Cascade)
        @(posedge vif.sec_pulse);
        @(posedge vif.clk); #1ns;
        scoreboard.check_time(0, 0, 0, "TC21_MIDNIGHT_CASCADE_00_00_00");

        // Tick 1s -> 00:00:01
        @(posedge vif.sec_pulse);
        @(posedge vif.clk); #1ns;
        scoreboard.check_time(0, 0, 1, "TC21_NEW_DAY_TICK_ONE");
    endtask

    //==========================================================================
    // Main Testbench Process
    //==========================================================================
    initial begin
        $display("\n================================================================================");
        $display("   STARTING HMS_TIMER SYSTEMVERILOG VERIFICATION ENVIRONMENT (QUESTASIM)        ");
        $display("================================================================================");

        // Instantiate testbench objects
        driver     = new(vif);
        scoreboard = new(vif);
        coverage   = new(vif);

        // Execute Test Suite sequentially
        run_tc1_reset_recovery();
        run_tc2_normal_counting();
        run_tc3_fsm_navigation();
        run_tc4_second_adjustment();
        run_tc5_minute_adjustment();
        run_tc6_hour_adjustment();
        run_tc7_rollover_isolation();
        run_tc8_simultaneous_press();
        run_tc9_async_glitch_test();
        run_tc10_midnight_cascade();
        run_tc11_exhaustive_cross_stimulus();
        run_tc12_button_debouncer_and_autorepeat();
        run_tc13_inactivity_timeout_rollback();
        run_tc14_inactivity_keepalive();

        // Execute Extended Test Suite (TC15 to TC21)
        run_tc15_reset_corners();
        run_tc16_prescaler_precision();
        run_tc17_debounce_corners();
        run_tc18_wrap_and_isolation();
        run_tc19_commit_collision_and_priority();
        run_tc20_timeout_corners_and_collision();
        run_tc21_e2e_scenarios();

        // Print Coverage and Scorecard Reports
        driver.wait_cycles(10);
        coverage.report_coverage();
        scoreboard.report_summary();

        $display("Simulation completed at timestamp: %0t ns", $time);
        $finish;
    end

endmodule
