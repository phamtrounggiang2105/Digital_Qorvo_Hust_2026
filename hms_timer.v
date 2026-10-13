module hms_timer (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       sel_in,
    input  wire       up_in,
    input  wire       down_in,
    output wire [5:0] s_out,
    output wire [5:0] m_out,
    output wire [4:0] h_out
);

    // =========================================================================
    // 1. INTERNAL WIRE DECLARATIONS
    // =========================================================================
    // Reset and Clock signals
    wire        rst_n_s;
    wire        pulse_1khz;
    wire        pulse_1hz;
    wire        gclk;

    // Button and FSM control signals
    wire        btn_sel_press_fsm;
    wire        btn_up_press;
    wire        btn_down_press;
    wire        btn_act_fsm;
    wire        fsm_normal;
    wire        fsm_edit_en_sec;
    wire        fsm_edit_en_min;
    wire        fsm_edit_en_hour;
    wire        fsm_load;
    wire        edited;

    // Real-time counter outputs
    wire [5:0]  sec_rt;
    wire [5:0]  min_rt;
    wire [4:0]  hour_rt;


    // =========================================================================
    // 2. RESET SYNCHRONIZATION & CLOCK GENERATION
    // =========================================================================
    // Synchronize asynchronous reset input
    reset_sync u_rst (
        .clk(clk), 
        .rst_n(rst_n), 
        .reset(rst_n_s)
    );

    // Generate 1 kHz (tick) and 1 Hz timebase pulses from 1 MHz master clock
    clk_divide u_div (
        .clk_in(clk), 
        .rst_n(rst_n_s),
        .pulse_1khz(pulse_1khz), 
        .pulse_1hz(pulse_1hz)
    );


    // =========================================================================
    // 3. BUTTON DEBOUNCE & SYNCHRONIZATION
    // =========================================================================
    // Process raw button inputs (sel, up, down) with debouncing and mode-dependent thresholds
    button u_btn (
        .clk(clk), 
        .rst_n(rst_n_s), 
        .pulse_1khz(pulse_1khz),
        .fsm_normal(fsm_normal),
        .sel_in(sel_in), 
        .up_in(up_in), 
        .down_in(down_in),
        .btn_sel_press_fsm(btn_sel_press_fsm),
        .btn_up_press(btn_up_press),
        .btn_down_press(btn_down_press),
        .btn_act_fsm(btn_act_fsm)
    );


    // =========================================================================
    // 4. CONTROL FINITE STATE MACHINE (FSM)
    // =========================================================================
    // Manages system states (NORMAL, SEC, MIN, HOUR) and timeout/load triggers
    fsm u_fsm (
        .clk(clk), 
        .rst_n(rst_n_s), 
        .pulse_1hz(pulse_1hz),
        .btn_sel_press_fsm(btn_sel_press_fsm),
        .btn_act_fsm(btn_act_fsm),
        .edited(edited),
        .fsm_normal(fsm_normal),
        .fsm_edit_en_sec(fsm_edit_en_sec),
        .fsm_edit_en_min(fsm_edit_en_min),
        .fsm_edit_en_hour(fsm_edit_en_hour),
        .fsm_load(fsm_load)
    );


    // =========================================================================
    // 5. INTEGRATED CLOCK GATING (ICG)
    // =========================================================================
    // Gates the master clock to save power during normal operation or force updates on load
    icg u_icg (
        .clk(clk), 
        .en(pulse_1hz | fsm_load), 
        .gclk(gclk)
    );

    
    // =========================================================================
    // 6. REAL-TIME CLOCK COUNTERS (SECONDS, MINUTES, HOURS)
    // =========================================================================
    sec u_sec (
        .gclk(gclk), 
        .rst_n(rst_n_s),
        .load_en(fsm_load), 
        .load_val(s_out),
        .sec_rt(sec_rt)
    );

    min u_min (
        .gclk(gclk), 
        .rst_n(rst_n_s),
        .sec_rt(sec_rt),
        .load_en(fsm_load), 
        .load_val(m_out),
        .min_rt(min_rt)
    );

    hour u_hour (
        .gclk(gclk), 
        .rst_n(rst_n_s),
        .sec_rt(sec_rt), 
        .min_rt(min_rt),
        .load_en(fsm_load), 
        .load_val(h_out),
        .hour_rt(hour_rt)
    );


    // =========================================================================
    // 7. TIME EDITING & DISPLAY MULTIPLEXER
    // =========================================================================
    // Handles manual adjustments during edit mode and multiplexes real-time vs. edit values to outputs
    edit_time u_edit (
        .clk(clk), 
        .rst_n(rst_n_s),
        .s_rt(sec_rt), 
        .m_rt(min_rt), 
        .h_rt(hour_rt),
        .fsm_normal(fsm_normal),
        .fsm_edit_en_sec(fsm_edit_en_sec),
        .fsm_edit_en_min(fsm_edit_en_min),
        .fsm_edit_en_hour(fsm_edit_en_hour),
        .button_down_press_sec(btn_down_press),  
        .button_up_press_sec(btn_up_press),
        .button_down_press_min(btn_down_press),  
        .button_up_press_min(btn_up_press),
        .button_down_press_hour(btn_down_press), 
        .button_up_press_hour(btn_up_press),
        .s_out(s_out), 
        .m_out(m_out), 
        .h_out(h_out),
        .edited(edited)
    );

endmodule