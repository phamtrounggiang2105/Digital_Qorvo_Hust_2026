//==============================================================================
// File: output_switch.sv
// Module: output_switch
// Description: Combinational Display Multiplexer selecting between:
//              - Real-time background counter values (when in MODE_RUN and not load_en)
//              - Interactive edit buffer values from mode_controller (when in MODE_ADJ_* or during load_en)
//              Pure zero-latency combinational logic (no flip-flops).
//              Bypasses background counter during load_en (1-cycle commit) to prevent 1-cycle glitch.
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module output_switch (
    input  logic       load_en,  // 1-Cycle Pulse to Synchronously Load Counters
    input  logic [1:0] adj_mode, // Current Operating Mode (00:RUN, 01:SEC, 10:MIN, 11:HOUR)
    input  logic [5:0] s_cnt,    // Real-Time Second from Background Counter
    input  logic [5:0] m_cnt,    // Real-Time Minute from Background Counter
    input  logic [4:0] h_cnt,    // Real-Time Hour from Background Counter
    input  logic [5:0] s_adj,    // Adjusted Second from Edit Buffer
    input  logic [5:0] m_adj,    // Adjusted Minute from Edit Buffer
    input  logic [4:0] h_adj,    // Adjusted Hour from Edit Buffer
    output logic [5:0] s_out,    // Top-Level Second Display Output
    output logic [5:0] m_out,    // Top-Level Minute Display Output
    output logic [4:0] h_out     // Top-Level Hour Display Output
);

    assign s_out = (adj_mode == 2'b00 && !load_en) ? s_cnt : s_adj;
    assign m_out = (adj_mode == 2'b00 && !load_en) ? m_cnt : m_adj;
    assign h_out = (adj_mode == 2'b00 && !load_en) ? h_cnt : h_adj;

endmodule
