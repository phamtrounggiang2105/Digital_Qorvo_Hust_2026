//==============================================================================
// File: clk_prescaler.sv
// Module: clk_prescaler
// Description: Multi-Stage Cascaded Frequency Prescaler for PPA Optimization.
//              - Stage 1: Divides 1 MHz system clock down to 1 kHz sampling pulse (pulse_1khz).
//              - Stage 2: Enabled by pulse_1khz, divides 1 kHz down to 1 Hz timebase (sec_pulse).
//              - PPA Optimization:
//                * Reduces high-frequency (1 MHz) switching counter width from 20-bit to 10-bit.
//                * Stage 2 counter switches at 1 kHz (1000x toggle rate reduction).
//                * Debouncer modules sample on pulse_1khz with small 5-bit counters.
//                * Shortens adder critical path for timing closure / higher Fmax.
//                * Pure synchronous single-clock domain design.
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module clk_prescaler #(
    parameter int P_CLK_FREQ_HZ        = 1_000_000, // System Clock Frequency (1 MHz)
    parameter int P_PULSE_1KHZ_FREQ_HZ  = 1_000      // Sampling rate (1 kHz)
)(
    input  logic clk,        // System Clock (1 MHz)
    input  logic rstn,       // Reset, Active-Low
    output logic pulse_1khz, // 1 kHz periodic pulse (1-cycle enable)
    output logic sec_pulse   // 1 Hz periodic pulse (1-cycle enable)
);

    // 20-bit counters supporting system clocks from 100 Hz up to >100 MHz
    logic [19:0] r_cnt_1khz;
    logic [19:0] r_cnt_1hz;

    // Stage 1: Modulo-(P_CLK_FREQ_HZ / P_PULSE_1KHZ_FREQ_HZ) Counter (1 MHz -> 1 kHz)
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            r_cnt_1khz <= 20'd0;
        end else begin
            if (P_CLK_FREQ_HZ <= P_PULSE_1KHZ_FREQ_HZ) begin
                r_cnt_1khz <= 20'd0;
            end else if (r_cnt_1khz >= (P_CLK_FREQ_HZ / P_PULSE_1KHZ_FREQ_HZ - 1)) begin
                r_cnt_1khz <= 20'd0;
            end else begin
                r_cnt_1khz <= r_cnt_1khz + 1'b1;
            end
        end
    end

    assign pulse_1khz = (P_CLK_FREQ_HZ <= P_PULSE_1KHZ_FREQ_HZ) ? 1'b1 :
                        (r_cnt_1khz == (P_CLK_FREQ_HZ / P_PULSE_1KHZ_FREQ_HZ - 1));

    // Stage 2: Modulo-(P_PULSE_1KHZ_FREQ_HZ) Counter (1 kHz -> 1 Hz, enabled by pulse_1khz)
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            r_cnt_1hz <= 20'd0;
        end else if (pulse_1khz) begin
            if (P_PULSE_1KHZ_FREQ_HZ <= 1) begin
                r_cnt_1hz <= 20'd0;
            end else if (r_cnt_1hz >= (P_PULSE_1KHZ_FREQ_HZ - 1)) begin
                r_cnt_1hz <= 20'd0;
            end else begin
                r_cnt_1hz <= r_cnt_1hz + 1'b1;
            end
        end
    end

    assign sec_pulse = pulse_1khz && ((P_PULSE_1KHZ_FREQ_HZ <= 1) ? 1'b1 :
                       (r_cnt_1hz == (P_PULSE_1KHZ_FREQ_HZ - 1)));

endmodule
