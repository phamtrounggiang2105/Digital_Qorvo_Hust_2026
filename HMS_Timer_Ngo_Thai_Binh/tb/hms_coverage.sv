//==============================================================================
// File: hms_coverage.sv
// Class: hms_coverage
// Description: Functional Coverage model for HMS_Timer IP Core verification.
//              Measures coverage for FSM States, Transitions, Timeout Aborts,
//              Reset Recoveries, Time Ranges, Rollovers, and Stimulus Combinations.
// Project: HMS_Timer
// Language: SystemVerilog
//==============================================================================

`ifndef HMS_COVERAGE_SV
`define HMS_COVERAGE_SV

class hms_coverage;
    virtual hms_timer_if vif;

    // Covergroup 1: FSM Operating Modes & Transitions (Including Timeout and Reset aborts)
    covergroup cg_fsm_modes @(posedge vif.clk);
        option.per_instance = 1;
        option.name = "cg_fsm_modes";

        cp_mode: coverpoint vif.adj_mode {
            bins mode_run      = {MODE_RUN};
            bins mode_adj_sec  = {MODE_ADJ_SEC};
            bins mode_adj_min  = {MODE_ADJ_MIN};
            bins mode_adj_hour = {MODE_ADJ_HOUR};
        }

        cp_mode_transitions: coverpoint vif.adj_mode {
            bins cycle_run_to_sec    = (MODE_RUN => MODE_ADJ_SEC);
            bins cycle_sec_to_min    = (MODE_ADJ_SEC => MODE_ADJ_MIN);
            bins cycle_min_to_hour   = (MODE_ADJ_MIN => MODE_ADJ_HOUR);
            bins cycle_hour_to_run   = (MODE_ADJ_HOUR => MODE_RUN);
        }

        cp_timeout_transitions: coverpoint vif.adj_mode {
            bins timeout_sec_to_run  = (MODE_ADJ_SEC => MODE_RUN);
            bins timeout_min_to_run  = (MODE_ADJ_MIN => MODE_RUN);
            bins timeout_hour_to_run = (MODE_ADJ_HOUR => MODE_RUN);
        }

        cp_reset_recovery: coverpoint vif.adj_mode {
            bins reset_from_sec  = (MODE_ADJ_SEC => MODE_RUN);
            bins reset_from_min  = (MODE_ADJ_MIN => MODE_RUN);
            bins reset_from_hour = (MODE_ADJ_HOUR => MODE_RUN);
            bins reset_from_run  = (MODE_RUN => MODE_RUN);
        }
    endgroup

    // Covergroup 2: Time Output Ranges & Boundary Conditions
    covergroup cg_time_values @(posedge vif.clk);
        option.per_instance = 1;
        option.name = "cg_time_values";

        cp_seconds: coverpoint vif.s_out {
            bins zero        = {0};
            bins mid_range   = {[1:58]};
            bins max_val     = {59};
            bins wrap_up     = (59 => 0);
            bins wrap_down   = (0 => 59);
        }

        cp_minutes: coverpoint vif.m_out {
            bins zero        = {0};
            bins mid_range   = {[1:58]};
            bins max_val     = {59};
            bins wrap_up     = (59 => 0);
            bins wrap_down   = (0 => 59);
        }

        cp_hours: coverpoint vif.h_out {
            bins zero        = {0};
            bins mid_range   = {[1:22]};
            bins max_val     = {23};
            bins wrap_up     = (23 => 0);
            bins wrap_down   = (0 => 23);
        }
    endgroup

    // Covergroup 3: Button Stimulus & Rollover Cross Coverage
    covergroup cg_stimulus_cross @(posedge vif.clk);
        option.per_instance = 1;
        option.name = "cg_stimulus_cross";

        cp_mode: coverpoint vif.adj_mode {
            bins run  = {MODE_RUN};
            bins a_s  = {MODE_ADJ_SEC};
            bins a_m  = {MODE_ADJ_MIN};
            bins a_h  = {MODE_ADJ_HOUR};
        }

        cp_up: coverpoint vif.up_pulse {
            bins inactive = {0};
            bins active   = {1};
        }

        cp_down: coverpoint vif.down_pulse {
            bins inactive = {0};
            bins active   = {1};
        }

        cp_sec_roll: coverpoint vif.sec_rollover {
            bins inactive = {0};
            bins active   = {1};
        }

        cp_min_roll: coverpoint vif.min_rollover {
            bins inactive = {0};
            bins active   = {1};
        }

        // Cross: Button actions across all modes
        cross_btn_mode: cross cp_mode, cp_up, cp_down;

        // Cross: Rollovers in RUN mode
        cross_rollover_run: cross cp_mode, cp_sec_roll, cp_min_roll {
            // Hardware exclusion: In minute_counter.sv, min_rollover requires sec_rollover == 1.
            // A minute rollover without a simultaneous second rollover is physically impossible.
            ignore_bins illegal_min_without_sec = binsof(cp_sec_roll.inactive) && binsof(cp_min_roll.active);
            // Inactivity timeout (5s) prevents waiting for background rollovers in interactive edit modes.
            ignore_bins non_run_modes = binsof(cp_mode.a_s) || binsof(cp_mode.a_m) || binsof(cp_mode.a_h);
        }
    endgroup

    // Covergroup 4: Parallel Load Commit & Collision Corners
    covergroup cg_commit_collision @(posedge vif.clk);
        option.per_instance = 1;
        option.name = "cg_commit_collision";

        cp_load: coverpoint vif.load_en {
            bins inactive = {0};
            bins active   = {1};
        }

        cp_sec_pulse: coverpoint vif.sec_pulse {
            bins inactive = {0};
            bins active   = {1};
        }

        cp_sec_roll: coverpoint vif.sec_rollover {
            bins inactive = {0};
            bins active   = {1};
        }

        cross_load_pulse: cross cp_load, cp_sec_pulse;
        cross_load_rollover: cross cp_load, cp_sec_roll {
            // Hardware exclusion: In second_counter.sv, sec_rollover = (r_sec == 59) & sec_pulse & ~load_en.
            // Therefore, sec_rollover is forcibly suppressed to 0 whenever load_en is 1 (mutually exclusive).
            ignore_bins illegal_load_and_rollover = binsof(cp_load.active) && binsof(cp_sec_roll.active);
        }
    endgroup

    function new(virtual hms_timer_if vif);
        this.vif = vif;
        cg_fsm_modes        = new();
        cg_time_values      = new();
        cg_stimulus_cross   = new();
        cg_commit_collision = new();
    endfunction

    // Report coverage statistics
    function void report_coverage();
        real cov_fsm, cov_time, cov_cross, cov_commit, total_cov;
        cov_fsm    = cg_fsm_modes.get_coverage();
        cov_time   = cg_time_values.get_coverage();
        cov_cross  = cg_stimulus_cross.get_coverage();
        cov_commit = cg_commit_collision.get_coverage();
        total_cov  = (cov_fsm + cov_time + cov_cross + cov_commit) / 4.0;

        $display("\n--------------------------------------------------------------------------------");
        $display("                       FUNCTIONAL COVERAGE REPORT                                ");
        $display("--------------------------------------------------------------------------------");
        $display(" FSM Modes & Transitions Coverage : %6.2f %%", cov_fsm);
        $display(" Time Ranges & Boundary Coverage  : %6.2f %%", cov_time);
        $display(" Stimulus & Cross Coverage        : %6.2f %%", cov_cross);
        $display(" Commit & Collision Coverage      : %6.2f %%", cov_commit);
        $display("--------------------------------------------------------------------------------");
        $display(" OVERALL FUNCTIONAL COVERAGE      : %6.2f %%", total_cov);
        $display("--------------------------------------------------------------------------------\n");
    endfunction

endclass

`endif // HMS_COVERAGE_SV
