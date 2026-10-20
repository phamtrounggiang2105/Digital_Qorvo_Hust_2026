//==============================================================================
// File: hms_driver.sv
// Class: hms_driver
// Description: SystemVerilog Driver class for generating asynchronous and
//              synchronous button stimulus (sel, up, down) and controlling reset.
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
        log_info($sformatf("Applying Asynchronous Reset for %0d clock cycles...", rst_cycles));
        vif.rstn <= 1'b0;
        repeat (rst_cycles) @(posedge vif.clk);
        vif.rstn <= 1'b1;
        repeat (2) @(posedge vif.clk);
        log_info("Reset released successfully.");
    endtask

    // Asynchronous reset assert during master clock HIGH phase
    task async_reset_clk_high();
        wait(vif.clk === 1'b1);
        #100ns;
        vif.rstn <= 1'b0;
        repeat (5) @(posedge vif.clk);
        vif.rstn <= 1'b1;
        repeat (2) @(posedge vif.clk);
    endtask

    // Asynchronous reset assert during master clock LOW phase
    task async_reset_clk_low();
        wait(vif.clk === 1'b0);
        #100ns;
        vif.rstn <= 1'b0;
        repeat (5) @(posedge vif.clk);
        vif.rstn <= 1'b1;
        repeat (2) @(posedge vif.clk);
    endtask

    // Wait N clock cycles
    task wait_cycles(int cycles);
        repeat (cycles) @(posedge vif.clk);
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

    // Simultaneous Select and Up Press
    task pulse_sel_up_simultaneous(int pulse_width = 20, int post_delay = 25);
        @(posedge vif.clk);
        vif.sel_in <= 1'b1;
        vif.up_in  <= 1'b1;
        repeat (pulse_width) @(posedge vif.clk);
        vif.sel_in <= 1'b0;
        vif.up_in  <= 1'b0;
        repeat (post_delay) @(posedge vif.clk);
    endtask

    // Simultaneous Select and Down Press
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
        vif.sel_in   <= 1'b1;
        vif.up_in    <= 1'b1;
        vif.down_in  <= 1'b1;
        repeat (pulse_width) @(posedge vif.clk);
        vif.sel_in   <= 1'b0;
        vif.up_in    <= 1'b0;
        vif.down_in  <= 1'b0;
        repeat (post_delay) @(posedge vif.clk);
    endtask

    // Inject narrow sub-cycle glitch (Metastability / Filter test)
    task inject_glitch(int glitch_duration_ns = 50);
        #10ns;
        vif.up_in <= 1'b1;
        #(glitch_duration_ns * 1ns);
        vif.up_in <= 1'b0;
        @(posedge vif.clk);
    endtask

    // Navigate FSM to a specific target mode
    task set_mode(hms_mode_e target_mode);
        while (vif.adj_mode !== target_mode) begin
            pulse_sel(20, 25);
        end
    endtask

endclass

`endif // HMS_DRIVER_SV
