//==============================================================================
// File: hms_timer_if.sv
// Interface: hms_timer_if
// Description: SystemVerilog Verification Interface for HMS_Timer IP Core,
//              equipped with Clocking Blocks, Modports, Internal Probes and
//              SystemVerilog Assertions (SVA) formal checks.
// Project: HMS_Timer
// Language: SystemVerilog
//==============================================================================

`timescale 1ns / 1ps

interface hms_timer_if (
    input logic clk
);
    // Asynchronous / Control inputs
    logic       rstn;
    logic       sel_in;
    logic       up_in;
    logic       down_in;

    // Time outputs
    logic [4:0] h_out;
    logic [5:0] m_out;
    logic [5:0] s_out;

    // Internal probe signals for deep-cycle verification
    logic                    rstn_sync;
    logic                    pulse_1khz;
    logic                    sel_pulse;
    logic                    up_pulse;
    logic                    down_pulse;
    logic                    sec_pulse;
    logic [1:0]              adj_mode;
    logic                    load_en;
    logic                    sec_rollover;
    logic                    min_rollover;
    logic [5:0]              adj_sec;
    logic [5:0]              adj_min;
    logic [4:0]              adj_hour;
    logic [5:0]              s_cnt;
    logic [5:0]              m_cnt;
    logic [4:0]              h_cnt;

    // White-box internal probe signals
    logic                    meta_rstn;
    logic                    sync_rstn;
    logic [19:0]             r_cnt_1khz;
    logic [19:0]             r_cnt_1hz;
    logic [4:0]              sel_timer_cnt;
    logic [4:0]              up_timer_cnt;
    logic [4:0]              down_timer_cnt;
    logic                    sel_debounced;
    logic                    up_debounced;
    logic                    down_debounced;
    logic [3:0]              timeout_cnt;

    //--------------------------------------------------------------------------
    // Driver Clocking Block (Synchronous stimulus driving)
    //--------------------------------------------------------------------------
    clocking cb_drv @(posedge clk);
        default input #1ns output #1ns;
        output sel_in;
        output up_in;
        output down_in;
        input  rstn;
        input  h_out;
        input  m_out;
        input  s_out;
        input  adj_mode;
    endclocking

    //--------------------------------------------------------------------------
    // Monitor Clocking Block (Cycle-accurate output sampling)
    //--------------------------------------------------------------------------
    clocking cb_mon @(posedge clk);
        default input #1ns;
        input rstn;
        input sel_in;
        input up_in;
        input down_in;
        input h_out;
        input m_out;
        input s_out;
        input sel_pulse;
        input up_pulse;
        input down_pulse;
        input sec_pulse;
        input adj_mode;
        input load_en;
        input sec_rollover;
        input min_rollover;
        input adj_sec;
        input adj_min;
        input adj_hour;
        input s_cnt;
        input m_cnt;
        input h_cnt;
    endclocking

    // Modports
    modport DRV (clocking cb_drv, output rstn, output sel_in, output up_in, output down_in);
    modport MON (clocking cb_mon);
    modport DUT (
        input  clk, rstn, sel_in, up_in, down_in,
        output h_out, m_out, s_out
    );

    //==========================================================================
    // SVA (SystemVerilog Assertions) - Formal & Dynamic Verification Rules
    //==========================================================================

    // A1: Seconds Output Range Check (0 <= s_out <= 59)
    property p_s_out_range;
        @(posedge clk) disable iff (!rstn_sync)
        (s_out <= 6'd59);
    endproperty
    assert_s_out_range: assert property (p_s_out_range)
        else $error("[SVA FAIL] s_out out of range (0..59): %0d", s_out);

    // A2: Minutes Output Range Check (0 <= m_out <= 59)
    property p_m_out_range;
        @(posedge clk) disable iff (!rstn_sync)
        (m_out <= 6'd59);
    endproperty
    assert_m_out_range: assert property (p_m_out_range)
        else $error("[SVA FAIL] m_out out of range (0..59): %0d", m_out);

    // A3: Hours Output Range Check (0 <= h_out <= 23)
    property p_h_out_range;
        @(posedge clk) disable iff (!rstn_sync)
        (h_out <= 5'd23);
    endproperty
    assert_h_out_range: assert property (p_h_out_range)
        else $error("[SVA FAIL] h_out out of range (0..23): %0d", h_out);

    // A4: Synchronous Reset Clear Check (Checked on cycle N+1 after synchronous reset active)
    property p_reset_state;
        @(posedge clk)
        (!rstn_sync) |=> (s_out == 6'd0 && m_out == 6'd0 && h_out == 5'd0);
    endproperty
    assert_reset_state: assert property (p_reset_state)
        else $error("[SVA FAIL] Outputs not zero during reset: H=%0d M=%0d S=%0d", h_out, m_out, s_out);

    // A5: Rollover Synchronization Check
    property p_sec_rollover_sync;
        @(posedge clk) disable iff (!rstn_sync)
        sec_rollover |-> sec_pulse;
    endproperty
    assert_sec_rollover_sync: assert property (p_sec_rollover_sync)
        else $error("[SVA FAIL] sec_rollover active without sec_pulse!");

    property p_min_rollover_sync;
        @(posedge clk) disable iff (!rstn_sync)
        min_rollover |-> sec_rollover;
    endproperty
    assert_min_rollover_sync: assert property (p_min_rollover_sync)
        else $error("[SVA FAIL] min_rollover active without sec_rollover!");

    // A6: FSM Legal Transitions Property
    property p_fsm_legal_transitions;
        @(posedge clk) disable iff (!rstn_sync)
        (adj_mode != $past(adj_mode)) |->
            (($past(adj_mode) == 2'b00 && adj_mode == 2'b01) ||
             ($past(adj_mode) == 2'b01 && adj_mode == 2'b10) ||
             ($past(adj_mode) == 2'b10 && adj_mode == 2'b11) ||
             ($past(adj_mode) == 2'b11 && adj_mode == 2'b00) ||
             ($past(adj_mode) != 2'b00 && adj_mode == 2'b00));
    endproperty
    assert_fsm_legal_transitions: assert property (p_fsm_legal_transitions)
        else $error("[SVA FAIL] Illegal FSM transition from %0b to %0b", $past(adj_mode), adj_mode);

    // A7: FSM Valid State Property
    property p_fsm_valid_state;
        @(posedge clk)
        !$isunknown(adj_mode);
    endproperty
    assert_fsm_valid_state: assert property (p_fsm_valid_state)
        else $error("[SVA FAIL] Unknown state encoding on adj_mode: %b", adj_mode);

    // A8: Prescaler Pulse 1Hz Single-Cycle Width Check
    property p_sec_pulse_width;
        @(posedge clk) disable iff (!rstn_sync)
        sec_pulse |=> !sec_pulse;
    endproperty
    assert_sec_pulse_width: assert property (p_sec_pulse_width)
        else $error("[SVA FAIL] sec_pulse held active for more than 1 cycle!");

    // A9: Load Enable Single-Cycle Pulse Width Check
    property p_load_en_pulse_width;
        @(posedge clk) disable iff (!rstn_sync)
        load_en |=> !load_en;
    endproperty
    assert_load_en_pulse_width: assert property (p_load_en_pulse_width)
        else $error("[SVA FAIL] load_en held active for more than 1 cycle!");

    // A10: Load Priority Over Rollover Suppression
    property p_load_over_rollover;
        @(posedge clk) disable iff (!rstn_sync)
        load_en |-> (!sec_rollover && !min_rollover);
    endproperty
    assert_load_over_rollover: assert property (p_load_over_rollover)
        else $error("[SVA FAIL] Rollover active during load_en commit!");

    // A11: Output Switch Bypass Anti-Glitch Property
    property p_output_switch_bypass;
        @(posedge clk) disable iff (!rstn_sync)
        load_en |-> (s_out == adj_sec && m_out == adj_min && h_out == adj_hour);
    endproperty
    assert_output_switch_bypass: assert property (p_output_switch_bypass)
        else $error("[SVA FAIL] Output switch did not retain edit buffer during commit load_en!");

    // A12: Button Pulse Width Checks (Single Cycle Master Clock)
    property p_sel_pulse_width;
        @(posedge clk) disable iff (!rstn_sync)
        sel_pulse |=> !sel_pulse;
    endproperty
    assert_sel_pulse_width: assert property (p_sel_pulse_width)
        else $error("[SVA FAIL] sel_pulse held active for more than 1 cycle!");

    property p_up_pulse_width;
        @(posedge clk) disable iff (!rstn_sync)
        up_pulse |=> !up_pulse;
    endproperty
    assert_up_pulse_width: assert property (p_up_pulse_width)
        else $error("[SVA FAIL] up_pulse held active for more than 1 cycle!");

    property p_down_pulse_width;
        @(posedge clk) disable iff (!rstn_sync)
        down_pulse |=> !down_pulse;
    endproperty
    assert_down_pulse_width: assert property (p_down_pulse_width)
        else $error("[SVA FAIL] down_pulse held active for more than 1 cycle!");

    // A13: Real-Time Counter Hold Stability Properties
    property p_second_counter_hold;
        @(posedge clk) disable iff (!rstn_sync)
        (!load_en && !sec_pulse) |=> (s_cnt == $past(s_cnt));
    endproperty
    assert_second_counter_hold: assert property (p_second_counter_hold)
        else $error("[SVA FAIL] s_cnt changed without sec_pulse or load_en!");

    property p_minute_counter_hold;
        @(posedge clk) disable iff (!rstn_sync)
        (!load_en && !sec_rollover) |=> (m_cnt == $past(m_cnt));
    endproperty
    assert_minute_counter_hold: assert property (p_minute_counter_hold)
        else $error("[SVA FAIL] m_cnt changed without sec_rollover or load_en!");

    property p_hour_counter_hold;
        @(posedge clk) disable iff (!rstn_sync)
        (!load_en && !min_rollover) |=> (h_cnt == $past(h_cnt));
    endproperty
    assert_hour_counter_hold: assert property (p_hour_counter_hold)
        else $error("[SVA FAIL] h_cnt changed without min_rollover or load_en!");

    // A14: Timeout Rollback Without Load_en Property
    property p_timeout_no_load_en;
        @(posedge clk) disable iff (!rstn_sync)
        ($past(adj_mode) != 2'b00 && adj_mode == 2'b00 && !$past(sel_pulse)) |-> (!load_en);
    endproperty
    assert_timeout_no_load_en: assert property (p_timeout_no_load_en)
        else $error("[SVA FAIL] load_en asserted during timeout rollback!");

    // A15: Spurious Rollover Suppression Properties
    property p_sec_spurious_suppress;
        @(posedge clk) disable iff (!rstn_sync)
        (s_cnt != 6'd59) |-> (!sec_rollover);
    endproperty
    assert_sec_spurious_suppress: assert property (p_sec_spurious_suppress)
        else $error("[SVA FAIL] sec_rollover active when s_cnt != 59!");

    property p_min_spurious_suppress;
        @(posedge clk) disable iff (!rstn_sync)
        (m_cnt != 6'd59) |-> (!min_rollover);
    endproperty
    assert_min_spurious_suppress: assert property (p_min_spurious_suppress)
        else $error("[SVA FAIL] min_rollover active when m_cnt != 59!");

    property p_load_suppresses_rollover;
        @(posedge clk) disable iff (!rstn_sync)
        load_en |-> (!sec_rollover && !min_rollover);
    endproperty
    assert_load_suppresses_rollover: assert property (p_load_suppresses_rollover)
        else $error("[SVA FAIL] sec_rollover or min_rollover active when load_en = 1!");

    // A16: Output Switch Normal vs Adjust Routing Properties
    property p_output_switch_run;
        @(posedge clk) disable iff (!rstn_sync)
        (adj_mode == 2'b00 && !load_en) |-> (s_out == s_cnt && m_out == m_cnt && h_out == h_cnt);
    endproperty
    assert_output_switch_run: assert property (p_output_switch_run)
        else $error("[SVA FAIL] Output switch mismatch in MODE_RUN!");

    property p_output_switch_adj;
        @(posedge clk) disable iff (!rstn_sync)
        (adj_mode != 2'b00) |-> (s_out == adj_sec && m_out == adj_min && h_out == adj_hour);
    endproperty
    assert_output_switch_adj: assert property (p_output_switch_adj)
        else $error("[SVA FAIL] Output switch mismatch in MODE_ADJ!");

endinterface
