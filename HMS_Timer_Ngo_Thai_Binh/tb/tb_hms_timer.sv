//==============================================================================
// File: tb_hms_timer.sv
// Module: tb_hms_timer (Top Verification Testbench)
// Description: Comprehensive SystemVerilog Verification Environment for
//              HMS_Timer IP Core against all 133 specification requirements
//              defined in the expanded test plan.
//              Features:
//              - 133 Individual Testcases covering all 6 functional sections
//              - Command-line test selector (+TESTNAME=<name>)
//              - Golden Reference Model & Cycle-accurate Scoreboard
//              - SystemVerilog Concurrent Assertions (SVA) Checkers
//              - Comprehensive Functional Coverage Model
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
    // 1 MHz Master Clock -> Period = 1000 ns (1 us)
    localparam realtime PL_CLK_PERIOD = 1000ns;

    // Simulation Prescaler settings (Fast simulation)
    localparam int PL_SIM_CLK_FREQ_HZ   = 100;
    localparam int PL_SIM_1KHZ_FREQ_HZ  = 100;
    localparam int PL_DEBOUNCE_PULSES   = 20;
    localparam int PL_TIMEOUT_SEC       = 5;

    // Master Clock generator
    logic clk;
    initial begin
        clk = 1'b0;
        forever #(PL_CLK_PERIOD / 2.0) clk = ~clk;
    end

    // Interface instantiation
    hms_timer_if vif (
        .clk(clk)
    );

    // DUT Instantiation
    hms_timer #(
        .P_CLK_FREQ_HZ        (PL_SIM_CLK_FREQ_HZ),
        .P_PULSE_1KHZ_FREQ_HZ (PL_SIM_1KHZ_FREQ_HZ),
        .P_DEBOUNCE_PULSES    (PL_DEBOUNCE_PULSES),
        .P_TIMEOUT_SEC        (PL_TIMEOUT_SEC)
    ) dut (
        .clk     (vif.clk),
        .rstn    (vif.rstn),
        .sel_in  (vif.sel_in),
        .up_in   (vif.up_in),
        .down_in (vif.down_in),
        .h_out   (vif.h_out),
        .m_out   (vif.m_out),
        .s_out   (vif.s_out)
    );

    // Probe assignments for interface and verification visibility
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

    // White-box probe connections
    assign vif.meta_rstn      = dut.u_reset_sync.meta_rstn;
    assign vif.sync_rstn      = dut.u_reset_sync.sync_rstn;
    assign vif.r_cnt_1khz     = dut.u_clk_prescaler.r_cnt_1khz;
    assign vif.r_cnt_1hz      = dut.u_clk_prescaler.r_cnt_1hz;
    assign vif.sel_timer_cnt  = dut.u_button_controller.u_debouncer_sel.timer_cnt;
    assign vif.up_timer_cnt   = dut.u_button_controller.u_debouncer_up.timer_cnt;
    assign vif.down_timer_cnt = dut.u_button_controller.u_debouncer_down.timer_cnt;
    assign vif.sel_debounced  = dut.u_button_controller.u_debouncer_sel.debounced_btn;
    assign vif.up_debounced   = dut.u_button_controller.u_debouncer_up.debounced_btn;
    assign vif.down_debounced = dut.u_button_controller.u_debouncer_down.debounced_btn;
    assign vif.timeout_cnt    = dut.u_mode_controller.timeout_cnt;

    // Testbench OOP Components
    hms_driver     driver;
    hms_scoreboard scoreboard;
    hms_coverage   coverage;

    // Test tracking counters
    int g_test_count  = 0;
    int g_test_passed = 0;
    int g_test_failed = 0;

    // Logging helpers for test execution
    function void start_test_header(string id, string name);
        g_test_count++;
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TESTCASE [%0d/133] (ID: %s) : %s", g_test_count, id, name);
        $display("--------------------------------------------------------------------------------");
    endfunction

    function void finish_test_footer(string id, string name, int errs_before, hms_scoreboard sb);
        if (sb.failed_checks == errs_before) begin
            g_test_passed++;
            log_pass($sformatf("TEST [%s] PASSED: %s", id, name));
        end else begin
            g_test_failed++;
            log_fail($sformatf("TEST [%s] FAILED: %s (%0d failure(s))", id, name, sb.failed_checks - errs_before));
        end
    endfunction

    // Include testcase modules for all 6 sections
    `include "tests/tc_sec1_reset_clock.sv"
    `include "tests/tc_sec2_button_debouncer.sv"
    `include "tests/tc_sec3_fsm_timeout.sv"
    `include "tests/tc_sec4_buffers_display.sv"
    `include "tests/tc_sec5_counters_cascade.sv"
    `include "tests/tc_sec6_integration_sva.sv"

    // Section 1: Reset & Clock Management (26 items: 1.1.1 - 1.5.6)
    task automatic run_section_1();
        $display("\n================================================================================");
        $display("   SECTION 1: RESET & CLOCK MANAGEMENT (26 ITEMS)                              ");
        $display("================================================================================");
        run_tc_1_1_1(driver, scoreboard, vif);
        run_tc_1_1_2(driver, scoreboard, vif);
        run_tc_1_1_3(driver, scoreboard, vif);
        run_tc_1_1_4(driver, scoreboard, vif);
        run_tc_1_1_5(driver, scoreboard, vif);
        run_tc_1_2_1(driver, scoreboard, vif);
        run_tc_1_2_2(driver, scoreboard, vif);
        run_tc_1_3_1(driver, scoreboard, vif);
        run_tc_1_3_2(driver, scoreboard, vif);
        run_tc_1_3_3(driver, scoreboard, vif);
        run_tc_1_4_1(driver, scoreboard, vif);
        run_tc_1_4_2(driver, scoreboard, vif);
        run_tc_1_4_3(driver, scoreboard, vif);
        run_tc_1_4_4(driver, scoreboard, vif);
        run_tc_1_4_5(driver, scoreboard, vif);
        run_tc_1_4_6(driver, scoreboard, vif);
        run_tc_1_4_7(driver, scoreboard, vif);
        run_tc_1_4_8(driver, scoreboard, vif);
        run_tc_1_4_9(driver, scoreboard, vif);
        run_tc_1_4_10(driver, scoreboard, vif);
        run_tc_1_5_1(driver, scoreboard, vif);
        run_tc_1_5_2(driver, scoreboard, vif);
        run_tc_1_5_3(driver, scoreboard, vif);
        run_tc_1_5_4(driver, scoreboard, vif);
        run_tc_1_5_5(driver, scoreboard, vif);
        run_tc_1_5_6(driver, scoreboard, vif);
    endtask

    // Section 2: Button Processing & Debouncing / Glitch (17 items: 2.1.1 - 2.2.6)
    task automatic run_section_2();
        $display("\n================================================================================");
        $display("   SECTION 2: BUTTON PROCESSING & DEBOUNCING / GLITCH IMMUNITY (17 ITEMS)       ");
        $display("================================================================================");
        run_tc_2_1_1(driver, scoreboard, vif);
        run_tc_2_1_2(driver, scoreboard, vif);
        run_tc_2_1_3(driver, scoreboard, vif);
        run_tc_2_1_4(driver, scoreboard, vif);
        run_tc_2_1_5(driver, scoreboard, vif);
        run_tc_2_1_6(driver, scoreboard, vif);
        run_tc_2_1_7(driver, scoreboard, vif);
        run_tc_2_1_8(driver, scoreboard, vif);
        run_tc_2_1_9(driver, scoreboard, vif);
        run_tc_2_1_10(driver, scoreboard, vif);
        run_tc_2_1_11(driver, scoreboard, vif);
        run_tc_2_2_1(driver, scoreboard, vif);
        run_tc_2_2_2(driver, scoreboard, vif);
        run_tc_2_2_3(driver, scoreboard, vif);
        run_tc_2_2_4(driver, scoreboard, vif);
        run_tc_2_2_5(driver, scoreboard, vif);
        run_tc_2_2_6(driver, scoreboard, vif);
    endtask

    // Section 3: Mode Controller FSM & Inactivity Management (22 items: 3.1.1 - 3.3.4)
    task automatic run_section_3();
        $display("\n================================================================================");
        $display("   SECTION 3: MODE CONTROLLER FSM & INACTIVITY MANAGEMENT (22 ITEMS)           ");
        $display("================================================================================");
        run_tc_3_1_1(driver, scoreboard, vif);
        run_tc_3_1_2(driver, scoreboard, vif);
        run_tc_3_1_3(driver, scoreboard, vif);
        run_tc_3_1_4(driver, scoreboard, vif);
        run_tc_3_1_5(driver, scoreboard, vif);
        run_tc_3_1_6(driver, scoreboard, vif);
        run_tc_3_1_7(driver, scoreboard, vif);
        run_tc_3_2_1(driver, scoreboard, vif);
        run_tc_3_2_2(driver, scoreboard, vif);
        run_tc_3_2_3(driver, scoreboard, vif);
        run_tc_3_2_4(driver, scoreboard, vif);
        run_tc_3_2_5(driver, scoreboard, vif);
        run_tc_3_2_6(driver, scoreboard, vif);
        run_tc_3_2_7(driver, scoreboard, vif);
        run_tc_3_2_8(driver, scoreboard, vif);
        run_tc_3_2_9(driver, scoreboard, vif);
        run_tc_3_2_10(driver, scoreboard, vif);
        run_tc_3_2_11(driver, scoreboard, vif);
        run_tc_3_3_1(driver, scoreboard, vif);
        run_tc_3_3_2(driver, scoreboard, vif);
        run_tc_3_3_3(driver, scoreboard, vif);
        run_tc_3_3_4(driver, scoreboard, vif);
    endtask

    // Section 4: Edit Buffers & Display Output Multiplexing (22 items: 4.1.1 - 4.5.5)
    task automatic run_section_4();
        $display("\n================================================================================");
        $display("   SECTION 4: EDIT BUFFERS & DISPLAY OUTPUT MULTIPLEXING (22 ITEMS)            ");
        $display("================================================================================");
        run_tc_4_1_1(driver, scoreboard, vif);
        run_tc_4_1_2(driver, scoreboard, vif);
        run_tc_4_1_3(driver, scoreboard, vif);
        run_tc_4_1_4(driver, scoreboard, vif);
        run_tc_4_2_1(driver, scoreboard, vif);
        run_tc_4_2_2(driver, scoreboard, vif);
        run_tc_4_2_3(driver, scoreboard, vif);
        run_tc_4_2_4(driver, scoreboard, vif);
        run_tc_4_3_1(driver, scoreboard, vif);
        run_tc_4_3_2(driver, scoreboard, vif);
        run_tc_4_3_3(driver, scoreboard, vif);
        run_tc_4_3_4(driver, scoreboard, vif);
        run_tc_4_3_5(driver, scoreboard, vif);
        run_tc_4_4_1(driver, scoreboard, vif);
        run_tc_4_4_2(driver, scoreboard, vif);
        run_tc_4_4_3(driver, scoreboard, vif);
        run_tc_4_4_4(driver, scoreboard, vif);
        run_tc_4_5_1(driver, scoreboard, vif);
        run_tc_4_5_2(driver, scoreboard, vif);
        run_tc_4_5_3(driver, scoreboard, vif);
        run_tc_4_5_4(driver, scoreboard, vif);
        run_tc_4_5_5(driver, scoreboard, vif);
    endtask

    // Section 5: Real-Time Counters & Cascade Rollover (20 items: 5.1.1 - 5.3.8)
    task automatic run_section_5();
        $display("\n================================================================================");
        $display("   SECTION 5: REAL-TIME COUNTERS & CASCADE ROLLOVER (20 ITEMS)                  ");
        $display("================================================================================");
        run_tc_5_1_1(driver, scoreboard, vif);
        run_tc_5_1_2(driver, scoreboard, vif);
        run_tc_5_1_3(driver, scoreboard, vif);
        run_tc_5_1_4(driver, scoreboard, vif);
        run_tc_5_1_5(driver, scoreboard, vif);
        run_tc_5_1_6(driver, scoreboard, vif);
        run_tc_5_1_7(driver, scoreboard, vif);
        run_tc_5_1_8(driver, scoreboard, vif);
        run_tc_5_2_1(driver, scoreboard, vif);
        run_tc_5_2_2(driver, scoreboard, vif);
        run_tc_5_2_3(driver, scoreboard, vif);
        run_tc_5_2_4(driver, scoreboard, vif);
        run_tc_5_3_1(driver, scoreboard, vif);
        run_tc_5_3_2(driver, scoreboard, vif);
        run_tc_5_3_3(driver, scoreboard, vif);
        run_tc_5_3_4(driver, scoreboard, vif);
        run_tc_5_3_5(driver, scoreboard, vif);
        run_tc_5_3_6(driver, scoreboard, vif);
        run_tc_5_3_7(driver, scoreboard, vif);
        run_tc_5_3_8(driver, scoreboard, vif);
    endtask

    // Section 6: Top Integration, Formal SVA & Verification Closure (26 items: 6.1.1 - 6.3.7)
    task automatic run_section_6();
        $display("\n================================================================================");
        $display("   SECTION 6: TOP INTEGRATION, FORMAL SVA & CLOSURE (26 ITEMS)                  ");
        $display("================================================================================");
        run_tc_6_1_1(driver, scoreboard, vif);
        run_tc_6_1_2(driver, scoreboard, vif);
        run_tc_6_1_3(driver, scoreboard, vif);
        run_tc_6_1_4(driver, scoreboard, vif);
        run_tc_6_1_5(driver, scoreboard, vif);
        run_tc_6_1_6(driver, scoreboard, vif);
        run_tc_6_1_7(driver, scoreboard, vif);
        run_tc_6_1_8(driver, scoreboard, vif);
        run_tc_6_2_1(driver, scoreboard, vif);
        run_tc_6_2_2(driver, scoreboard, vif);
        run_tc_6_2_3(driver, scoreboard, vif);
        run_tc_6_2_4(driver, scoreboard, vif);
        run_tc_6_2_5(driver, scoreboard, vif);
        run_tc_6_2_6(driver, scoreboard, vif);
        run_tc_6_2_7(driver, scoreboard, vif);
        run_tc_6_2_8(driver, scoreboard, vif);
        run_tc_6_2_9(driver, scoreboard, vif);
        run_tc_6_2_10(driver, scoreboard, vif);
        run_tc_6_2_11(driver, scoreboard, vif);
        run_tc_6_3_1(driver, scoreboard, vif);
        run_tc_6_3_2(driver, scoreboard, vif);
        run_tc_6_3_3(driver, scoreboard, vif);
        run_tc_6_3_4(driver, scoreboard, vif);
        run_tc_6_3_5(driver, scoreboard, vif);
        run_tc_6_3_6(driver, scoreboard, vif);
        run_tc_6_3_7(driver, scoreboard, vif);
    endtask

    // Run all 133 testcases sequentially
    task automatic run_all_tests();
        run_section_1();
        run_section_2();
        run_section_3();
        run_section_4();
        run_section_5();
        run_section_6();
    endtask

    // Dispatcher for running individual testcase or section via +TESTNAME=<arg>
    task automatic dispatch_test(string test_name);
        case (test_name)
            "all", "": run_all_tests();
            "sec1":    run_section_1();
            "sec2":    run_section_2();
            "sec3":    run_section_3();
            "sec4":    run_section_4();
            "sec5":    run_section_5();
            "sec6":    run_section_6();

            // Section 1 individual tests
            "1.1.1", "tc_1_1_1": run_tc_1_1_1(driver, scoreboard, vif);
            "1.1.2", "tc_1_1_2": run_tc_1_1_2(driver, scoreboard, vif);
            "1.1.3", "tc_1_1_3": run_tc_1_1_3(driver, scoreboard, vif);
            "1.1.4", "tc_1_1_4": run_tc_1_1_4(driver, scoreboard, vif);
            "1.1.5", "tc_1_1_5": run_tc_1_1_5(driver, scoreboard, vif);
            "1.2.1", "tc_1_2_1": run_tc_1_2_1(driver, scoreboard, vif);
            "1.2.2", "tc_1_2_2": run_tc_1_2_2(driver, scoreboard, vif);
            "1.3.1", "tc_1_3_1": run_tc_1_3_1(driver, scoreboard, vif);
            "1.3.2", "tc_1_3_2": run_tc_1_3_2(driver, scoreboard, vif);
            "1.3.3", "tc_1_3_3": run_tc_1_3_3(driver, scoreboard, vif);
            "1.4.1", "tc_1_4_1": run_tc_1_4_1(driver, scoreboard, vif);
            "1.4.2", "tc_1_4_2": run_tc_1_4_2(driver, scoreboard, vif);
            "1.4.3", "tc_1_4_3": run_tc_1_4_3(driver, scoreboard, vif);
            "1.4.4", "tc_1_4_4": run_tc_1_4_4(driver, scoreboard, vif);
            "1.4.5", "tc_1_4_5": run_tc_1_4_5(driver, scoreboard, vif);
            "1.4.6", "tc_1_4_6": run_tc_1_4_6(driver, scoreboard, vif);
            "1.4.7", "tc_1_4_7": run_tc_1_4_7(driver, scoreboard, vif);
            "1.4.8", "tc_1_4_8": run_tc_1_4_8(driver, scoreboard, vif);
            "1.4.9", "tc_1_4_9": run_tc_1_4_9(driver, scoreboard, vif);
            "1.4.10", "tc_1_4_10": run_tc_1_4_10(driver, scoreboard, vif);
            "1.5.1", "tc_1_5_1": run_tc_1_5_1(driver, scoreboard, vif);
            "1.5.2", "tc_1_5_2": run_tc_1_5_2(driver, scoreboard, vif);
            "1.5.3", "tc_1_5_3": run_tc_1_5_3(driver, scoreboard, vif);
            "1.5.4", "tc_1_5_4": run_tc_1_5_4(driver, scoreboard, vif);
            "1.5.5", "tc_1_5_5": run_tc_1_5_5(driver, scoreboard, vif);
            "1.5.6", "tc_1_5_6": run_tc_1_5_6(driver, scoreboard, vif);

            // Section 2 individual tests
            "2.1.1", "tc_2_1_1": run_tc_2_1_1(driver, scoreboard, vif);
            "2.1.2", "tc_2_1_2": run_tc_2_1_2(driver, scoreboard, vif);
            "2.1.3", "tc_2_1_3": run_tc_2_1_3(driver, scoreboard, vif);
            "2.1.4", "tc_2_1_4": run_tc_2_1_4(driver, scoreboard, vif);
            "2.1.5", "tc_2_1_5": run_tc_2_1_5(driver, scoreboard, vif);
            "2.1.6", "tc_2_1_6": run_tc_2_1_6(driver, scoreboard, vif);
            "2.1.7", "tc_2_1_7": run_tc_2_1_7(driver, scoreboard, vif);
            "2.1.8", "tc_2_1_8": run_tc_2_1_8(driver, scoreboard, vif);
            "2.1.9", "tc_2_1_9": run_tc_2_1_9(driver, scoreboard, vif);
            "2.1.10", "tc_2_1_10": run_tc_2_1_10(driver, scoreboard, vif);
            "2.1.11", "tc_2_1_11": run_tc_2_1_11(driver, scoreboard, vif);
            "2.2.1", "tc_2_2_1": run_tc_2_2_1(driver, scoreboard, vif);
            "2.2.2", "tc_2_2_2": run_tc_2_2_2(driver, scoreboard, vif);
            "2.2.3", "tc_2_2_3": run_tc_2_2_3(driver, scoreboard, vif);
            "2.2.4", "tc_2_2_4": run_tc_2_2_4(driver, scoreboard, vif);
            "2.2.5", "tc_2_2_5": run_tc_2_2_5(driver, scoreboard, vif);
            "2.2.6", "tc_2_2_6": run_tc_2_2_6(driver, scoreboard, vif);

            // Section 3 individual tests
            "3.1.1", "tc_3_1_1": run_tc_3_1_1(driver, scoreboard, vif);
            "3.1.2", "tc_3_1_2": run_tc_3_1_2(driver, scoreboard, vif);
            "3.1.3", "tc_3_1_3": run_tc_3_1_3(driver, scoreboard, vif);
            "3.1.4", "tc_3_1_4": run_tc_3_1_4(driver, scoreboard, vif);
            "3.1.5", "tc_3_1_5": run_tc_3_1_5(driver, scoreboard, vif);
            "3.1.6", "tc_3_1_6": run_tc_3_1_6(driver, scoreboard, vif);
            "3.1.7", "tc_3_1_7": run_tc_3_1_7(driver, scoreboard, vif);
            "3.2.1", "tc_3_2_1": run_tc_3_2_1(driver, scoreboard, vif);
            "3.2.2", "tc_3_2_2": run_tc_3_2_2(driver, scoreboard, vif);
            "3.2.3", "tc_3_2_3": run_tc_3_2_3(driver, scoreboard, vif);
            "3.2.4", "tc_3_2_4": run_tc_3_2_4(driver, scoreboard, vif);
            "3.2.5", "tc_3_2_5": run_tc_3_2_5(driver, scoreboard, vif);
            "3.2.6", "tc_3_2_6": run_tc_3_2_6(driver, scoreboard, vif);
            "3.2.7", "tc_3_2_7": run_tc_3_2_7(driver, scoreboard, vif);
            "3.2.8", "tc_3_2_8": run_tc_3_2_8(driver, scoreboard, vif);
            "3.2.9", "tc_3_2_9": run_tc_3_2_9(driver, scoreboard, vif);
            "3.2.10", "tc_3_2_10": run_tc_3_2_10(driver, scoreboard, vif);
            "3.2.11", "tc_3_2_11": run_tc_3_2_11(driver, scoreboard, vif);
            "3.3.1", "tc_3_3_1": run_tc_3_3_1(driver, scoreboard, vif);
            "3.3.2", "tc_3_3_2": run_tc_3_3_2(driver, scoreboard, vif);
            "3.3.3", "tc_3_3_3": run_tc_3_3_3(driver, scoreboard, vif);
            "3.3.4", "tc_3_3_4": run_tc_3_3_4(driver, scoreboard, vif);

            // Section 4 individual tests
            "4.1.1", "tc_4_1_1": run_tc_4_1_1(driver, scoreboard, vif);
            "4.1.2", "tc_4_1_2": run_tc_4_1_2(driver, scoreboard, vif);
            "4.1.3", "tc_4_1_3": run_tc_4_1_3(driver, scoreboard, vif);
            "4.1.4", "tc_4_1_4": run_tc_4_1_4(driver, scoreboard, vif);
            "4.2.1", "tc_4_2_1": run_tc_4_2_1(driver, scoreboard, vif);
            "4.2.2", "tc_4_2_2": run_tc_4_2_2(driver, scoreboard, vif);
            "4.2.3", "tc_4_2_3": run_tc_4_2_3(driver, scoreboard, vif);
            "4.2.4", "tc_4_2_4": run_tc_4_2_4(driver, scoreboard, vif);
            "4.3.1", "tc_4_3_1": run_tc_4_3_1(driver, scoreboard, vif);
            "4.3.2", "tc_4_3_2": run_tc_4_3_2(driver, scoreboard, vif);
            "4.3.3", "tc_4_3_3": run_tc_4_3_3(driver, scoreboard, vif);
            "4.3.4", "tc_4_3_4": run_tc_4_3_4(driver, scoreboard, vif);
            "4.3.5", "tc_4_3_5": run_tc_4_3_5(driver, scoreboard, vif);
            "4.4.1", "tc_4_4_1": run_tc_4_4_1(driver, scoreboard, vif);
            "4.4.2", "tc_4_4_2": run_tc_4_4_2(driver, scoreboard, vif);
            "4.4.3", "tc_4_4_3": run_tc_4_4_3(driver, scoreboard, vif);
            "4.4.4", "tc_4_4_4": run_tc_4_4_4(driver, scoreboard, vif);
            "4.5.1", "tc_4_5_1": run_tc_4_5_1(driver, scoreboard, vif);
            "4.5.2", "tc_4_5_2": run_tc_4_5_2(driver, scoreboard, vif);
            "4.5.3", "tc_4_5_3": run_tc_4_5_3(driver, scoreboard, vif);
            "4.5.4", "tc_4_5_4": run_tc_4_5_4(driver, scoreboard, vif);
            "4.5.5", "tc_4_5_5": run_tc_4_5_5(driver, scoreboard, vif);

            // Section 5 individual tests
            "5.1.1", "tc_5_1_1": run_tc_5_1_1(driver, scoreboard, vif);
            "5.1.2", "tc_5_1_2": run_tc_5_1_2(driver, scoreboard, vif);
            "5.1.3", "tc_5_1_3": run_tc_5_1_3(driver, scoreboard, vif);
            "5.1.4", "tc_5_1_4": run_tc_5_1_4(driver, scoreboard, vif);
            "5.1.5", "tc_5_1_5": run_tc_5_1_5(driver, scoreboard, vif);
            "5.1.6", "tc_5_1_6": run_tc_5_1_6(driver, scoreboard, vif);
            "5.1.7", "tc_5_1_7": run_tc_5_1_7(driver, scoreboard, vif);
            "5.1.8", "tc_5_1_8": run_tc_5_1_8(driver, scoreboard, vif);
            "5.2.1", "tc_5_2_1": run_tc_5_2_1(driver, scoreboard, vif);
            "5.2.2", "tc_5_2_2": run_tc_5_2_2(driver, scoreboard, vif);
            "5.2.3", "tc_5_2_3": run_tc_5_2_3(driver, scoreboard, vif);
            "5.2.4", "tc_5_2_4": run_tc_5_2_4(driver, scoreboard, vif);
            "5.3.1", "tc_5_3_1": run_tc_5_3_1(driver, scoreboard, vif);
            "5.3.2", "tc_5_3_2": run_tc_5_3_2(driver, scoreboard, vif);
            "5.3.3", "tc_5_3_3": run_tc_5_3_3(driver, scoreboard, vif);
            "5.3.4", "tc_5_3_4": run_tc_5_3_4(driver, scoreboard, vif);
            "5.3.5", "tc_5_3_5": run_tc_5_3_5(driver, scoreboard, vif);
            "5.3.6", "tc_5_3_6": run_tc_5_3_6(driver, scoreboard, vif);
            "5.3.7", "tc_5_3_7": run_tc_5_3_7(driver, scoreboard, vif);
            "5.3.8", "tc_5_3_8": run_tc_5_3_8(driver, scoreboard, vif);

            // Section 6 individual tests
            "6.1.1", "tc_6_1_1": run_tc_6_1_1(driver, scoreboard, vif);
            "6.1.2", "tc_6_1_2": run_tc_6_1_2(driver, scoreboard, vif);
            "6.1.3", "tc_6_1_3": run_tc_6_1_3(driver, scoreboard, vif);
            "6.1.4", "tc_6_1_4": run_tc_6_1_4(driver, scoreboard, vif);
            "6.1.5", "tc_6_1_5": run_tc_6_1_5(driver, scoreboard, vif);
            "6.1.6", "tc_6_1_6": run_tc_6_1_6(driver, scoreboard, vif);
            "6.1.7", "tc_6_1_7": run_tc_6_1_7(driver, scoreboard, vif);
            "6.1.8", "tc_6_1_8": run_tc_6_1_8(driver, scoreboard, vif);
            "6.2.1", "tc_6_2_1": run_tc_6_2_1(driver, scoreboard, vif);
            "6.2.2", "tc_6_2_2": run_tc_6_2_2(driver, scoreboard, vif);
            "6.2.3", "tc_6_2_3": run_tc_6_2_3(driver, scoreboard, vif);
            "6.2.4", "tc_6_2_4": run_tc_6_2_4(driver, scoreboard, vif);
            "6.2.5", "tc_6_2_5": run_tc_6_2_5(driver, scoreboard, vif);
            "6.2.6", "tc_6_2_6": run_tc_6_2_6(driver, scoreboard, vif);
            "6.2.7", "tc_6_2_7": run_tc_6_2_7(driver, scoreboard, vif);
            "6.2.8", "tc_6_2_8": run_tc_6_2_8(driver, scoreboard, vif);
            "6.2.9", "tc_6_2_9": run_tc_6_2_9(driver, scoreboard, vif);
            "6.2.10", "tc_6_2_10": run_tc_6_2_10(driver, scoreboard, vif);
            "6.2.11", "tc_6_2_11": run_tc_6_2_11(driver, scoreboard, vif);
            "6.3.1", "tc_6_3_1": run_tc_6_3_1(driver, scoreboard, vif);
            "6.3.2", "tc_6_3_2": run_tc_6_3_2(driver, scoreboard, vif);
            "6.3.3", "tc_6_3_3": run_tc_6_3_3(driver, scoreboard, vif);
            "6.3.4", "tc_6_3_4": run_tc_6_3_4(driver, scoreboard, vif);
            "6.3.5", "tc_6_3_5": run_tc_6_3_5(driver, scoreboard, vif);
            "6.3.6", "tc_6_3_6": run_tc_6_3_6(driver, scoreboard, vif);
            "6.3.7", "tc_6_3_7": run_tc_6_3_7(driver, scoreboard, vif);

            default: begin
                $display("[ERROR] Unknown test name: %s. Running all tests instead.", test_name);
                run_all_tests();
            end
        endcase
    endtask

    //==========================================================================
    // Main Verification Process
    //==========================================================================
    string requested_test = "all";

    initial begin
        $display("\n================================================================================");
        $display("   STARTING HMS_TIMER SYSTEMVERILOG VERIFICATION ENVIRONMENT (QUESTASIM)        ");
        $display("   TOTAL TESTCASES IN EXPANDED PLAN: 133 SEPARATE VERIFICATION ITEMS            ");
        $display("================================================================================");

        // Parse command line plusargs
        if ($value$plusargs("TESTNAME=%s", requested_test)) begin
            $display("[INFO] Running requested test target: %s", requested_test);
        end else begin
            $display("[INFO] No +TESTNAME specified. Defaulting to full regression (all 133 items).");
            requested_test = "all";
        end

        // Instantiate verification components
        driver     = new(vif);
        scoreboard = new(vif);
        coverage   = new(vif);

        // Execute target test / regression suite
        dispatch_test(requested_test);

        // Final settling cycles
        driver.wait_cycles(10);

        // Print final reports
        coverage.report_coverage();

        $display("\n================================================================================");
        $display("                   OVERALL TESTCASE EXECUTION SUMMARY                           ");
        $display("================================================================================");
        $display(" TOTAL TESTCASES EXECUTED : %0d", g_test_count);
        $display(" PASSED TESTCASES         : %0d", g_test_passed);
        $display(" FAILED TESTCASES         : %0d", g_test_failed);
        $display("--------------------------------------------------------------------------------");

        scoreboard.report_summary();

        $display("Simulation completed at timestamp: %0t ns", $time);
        $finish;
    end

endmodule
