//==============================================================================
// File: button_debouncer.sv
// Module: button_debouncer
// Description: Pure Synchronous 20ms Debounce IP Core.
//              - Single-Clock Domain: Runs on master clock (clk) with clk_en.
//              - 2-Stage D-FF Synchronizer: Runs at master clock (1 MHz)
//                to eliminate metastability (meta_btn -> sync_btn).
//              - Debounce Counter: Requires P_DEBOUNCE_PULSES consecutive samples
//                at clk_en (1 kHz) to qualify state transitions.
//              - Glitch Rejection: Presses < P_DEBOUNCE_PULSES are strictly ignored.
//              - Event Generation: Emits synchronous 1-cycle master clock pulse
//                (btn_event) upon qualifying a valid press transition.
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module button_debouncer #(
    parameter int P_DEBOUNCE_PULSES = 20
)(
    input  logic clk,        // System clock: 1 MHz
    input  logic rstn,       // Active-low asynchronous reset
    input  logic clk_en,     // 1-cycle enable pulse at 1 kHz
    input  logic btn_in,     // Asynchronous active-high button input
    output logic btn_event   // Synchronous 1-clock-cycle press event
);

    // ---------------------------------------------------------
    // 1. Parameters
    // ---------------------------------------------------------
    localparam int COUNT_WIDTH =
        (P_DEBOUNCE_PULSES <= 1)
        ? 1
        : $clog2(P_DEBOUNCE_PULSES);

    localparam logic [COUNT_WIDTH-1:0] COUNT_LIMIT =
        (P_DEBOUNCE_PULSES <= 1) ? '0 : (P_DEBOUNCE_PULSES - 1);

    // ---------------------------------------------------------
    // 2. Two-stage synchronizer
    //    Runs at the full system clock (1 MHz)
    // ---------------------------------------------------------
    (* ASYNC_REG = "TRUE" *) logic meta_btn;
    (* ASYNC_REG = "TRUE" *) logic sync_btn;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            meta_btn <= 1'b0;
            sync_btn <= 1'b0;
        end else begin
            meta_btn <= btn_in;
            sync_btn <= meta_btn;
        end
    end

    // ---------------------------------------------------------
    // 3. Debounce counter and stable button state
    // ---------------------------------------------------------
    logic [COUNT_WIDTH-1:0] timer_cnt;
    logic                   debounced_btn;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            timer_cnt      <= '0;
            debounced_btn  <= 1'b0;
            btn_event      <= 1'b0;
        end else begin
            // Default: event is a one-clock-cycle pulse
            btn_event <= 1'b0;

            // Update debounce logic only at the 1 kHz enable
            if (clk_en) begin
                // Input matches the accepted state:
                // no transition to qualify, so clear the counter.
                if (sync_btn == debounced_btn) begin
                    timer_cnt <= '0;
                end else begin
                    // Input differs from the accepted state.
                    // Require P_DEBOUNCE_PULSES consecutive samples.
                    if (timer_cnt == COUNT_LIMIT) begin
                        debounced_btn  <= sync_btn;
                        timer_cnt      <= '0;

                        // Generate an event only for a valid press.
                        if (sync_btn == 1'b1) begin
                            btn_event <= 1'b1;
                        end
                    end else begin
                        timer_cnt <= timer_cnt + 1'b1;
                    end
                end
            end
            else begin
            end
        end
    end

endmodule
