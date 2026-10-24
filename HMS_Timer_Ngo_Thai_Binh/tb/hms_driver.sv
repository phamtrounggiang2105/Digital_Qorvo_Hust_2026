//==============================================================================
// File: hms_driver.sv
// Class: hms_driver
// Description: SystemVerilog Driver class for generating asynchronous and
//              synchronous button stimulus (sel, up, down) and controlling reset.
//              Provides comprehensive stimulus generation routines for all
//              functional, corner-case and stress testcases.
// Project: HMS_Timer
// Language: SystemVerilog
//==============================================================================

`ifndef HMS_DRIVER_SV
`define HMS_DRIVER_SV

class hms_driver;
    virtual hms_timer_if vif;

    function new(virtual hms_timer_if vif);
        this.vif = vif;
    endfunction

    // Initialize all driver signals
    task init_signals();
        vif.rstn    <= 1'b0;
        vif.sel_in  <= 1'b0;
        vif.up_in   <= 1'b0;
        vif.down_in <= 1'b0;
    endtask

    // Asynchronous Reset sequence
    task reset_dut(int rst_cycles = 10);
        vif.rstn <= 1'b0;
        repeat (rst_cycles) @(posedge vif.clk);
        vif.rstn <= 1'b1;
        repeat (2) @(posedge vif.clk);
    endtask

    // Asynchronous reset assert during master clock HIGH phase
    task async_reset_clk_high(int post_delay = 5);
        wait(vif.clk === 1'b1);
        #100ns;
        vif.rstn <= 1'b0;
        repeat (post_delay) @(posedge vif.clk);
        vif.rstn <= 1'b1;
        repeat (2) @(posedge vif.clk);
    endtask

    // Asynchronous reset assert during master clock LOW phase
    task async_reset_clk_low(int post_delay = 5);
        wait(vif.clk === 1'b0);
        #100ns;
        vif.rstn <= 1'b0;
        repeat (post_delay) @(posedge vif.clk);
        vif.rstn <= 1'b1;
        repeat (2) @(posedge vif.clk);
    endtask

    // Wait N clock cycles
    task wait_cycles(int cycles);
        repeat (cycles) @(posedge vif.clk);
    endtask

    // Wait N 1-second pulses
    task wait_sec_pulses(int count);
        repeat (count) @(posedge vif.sec_pulse);
        @(posedge vif.clk); #1ns;
    endtask

    // Press Select Button (generates rising edge, holds for pulse_width cycles, then drops)
    task pulse_sel(int pulse_width = 20, int post_delay = 25);
        @(posedge vif.clk);
        vif.sel_in <= 1'b1;
        repeat (pulse_width) @(posedge vif.clk);
        vif.sel_in <= 1'b0;
        repeat (post_delay) @(posedge vif.clk);
    endtask

    // Press Up Button
    task pulse_up(int pulse_width = 20, int post_delay = 25);
        @(posedge vif.clk);
        vif.up_in <= 1'b1;
        repeat (pulse_width) @(posedge vif.clk);
        vif.up_in <= 1'b0;
        repeat (post_delay) @(posedge vif.clk);
    endtask

    // Press Down Button
    task pulse_down(int pulse_width = 20, int post_delay = 25);
        @(posedge vif.clk);
        vif.down_in <= 1'b1;
        repeat (pulse_width) @(posedge vif.clk);
        vif.down_in <= 1'b0;
        repeat (post_delay) @(posedge vif.clk);
    endtask

    // Simultaneous Up and Down Press (Conflict test)
    task pulse_up_down_simultaneous(int pulse_width = 20, int post_delay = 25);
        @(posedge vif.clk);
        vif.up_in   <= 1'b1;
        vif.down_in <= 1'b1;
        repeat (pulse_width) @(posedge vif.clk);
        vif.up_in   <= 1'b0;
        vif.down_in <= 1'b0;
        repeat (post_delay) @(posedge vif.clk);
    endtask

    // Simultaneous SEL and UP Press (Priority test)
    task pulse_sel_up_simultaneous(int pulse_width = 20, int post_delay = 25);
        @(posedge vif.clk);
        vif.sel_in <= 1'b1;
        vif.up_in  <= 1'b1;
        repeat (pulse_width) @(posedge vif.clk);
        vif.sel_in <= 1'b0;
        vif.up_in  <= 1'b0;
        repeat (post_delay) @(posedge vif.clk);
    endtask

    // Simultaneous SEL and DOWN Press (Priority test)
    task pulse_sel_down_simultaneous(int pulse_width = 20, int post_delay = 25);
        @(posedge vif.clk);
        vif.sel_in   <= 1'b1;
        vif.down_in <= 1'b1;
        repeat (pulse_width) @(posedge vif.clk);
        vif.sel_in   <= 1'b0;
        vif.down_in <= 1'b0;
        repeat (post_delay) @(posedge vif.clk);
    endtask

    // Simultaneous All Three Buttons Press
    task pulse_all_three_simultaneous(int pulse_width = 20, int post_delay = 25);
        @(posedge vif.clk);
        vif.sel_in  <= 1'b1;
        vif.up_in   <= 1'b1;
        vif.down_in <= 1'b1;
        repeat (pulse_width) @(posedge vif.clk);
        vif.sel_in  <= 1'b0;
        vif.up_in   <= 1'b0;
        vif.down_in <= 1'b0;
        repeat (post_delay) @(posedge vif.clk);
    endtask

    // Navigate to target mode from current mode via minimum SEL pulses
    task set_mode(hms_mode_e target_mode);
        while (vif.adj_mode !== target_mode) begin
            pulse_sel();
        end
    endtask

    // Helper: Set time via interactive menu edit and commit to RUN
    task set_time_via_edit(int h, int m, int s);
        // Start from MODE_RUN
        if (vif.adj_mode !== MODE_RUN) begin
            set_mode(MODE_RUN);
        end

        // 1. Enter ADJ_SEC
        pulse_sel();
        // Adjust seconds
        while (vif.adj_sec != s[5:0]) begin
            if (s[5:0] > vif.adj_sec) pulse_up();
            else pulse_down();
        end

        // 2. Enter ADJ_MIN
        pulse_sel();
        while (vif.adj_min != m[5:0]) begin
            if (m[5:0] > vif.adj_min) pulse_up();
            else pulse_down();
        end

        // 3. Enter ADJ_HOUR
        pulse_sel();
        while (vif.adj_hour != h[4:0]) begin
            if (h[4:0] > vif.adj_hour) pulse_up();
            else pulse_down();
        end

        // 4. Commit to MODE_RUN
        // Align with start of prescaler cycle so post_delay (25 cycles) does not cross sec_pulse boundary
        @(posedge vif.clk);
        while (vif.r_cnt_1hz > 7'd10) @(posedge vif.clk);
        pulse_sel();
    endtask

    // Inject narrow sub-cycle asynchronous glitch on up_in
    task inject_glitch(realtime duration_ns = 50);
        #100ns;
        vif.up_in <= 1'b1;
        #(duration_ns * 1ns);
        vif.up_in <= 1'b0;
    endtask

    // Inject narrow sub-cycle glitch on rstn
    task inject_reset_glitch(realtime duration_ns = 50);
        #100ns;
        vif.rstn <= 1'b0;
        #(duration_ns * 1ns);
        vif.rstn <= 1'b1;
    endtask

endclass

`endif // HMS_DRIVER_SV
