module hms_timer (
    // Clock and Reset
    input  wire        clk,
    input  wire        rstn,

    // Button inputs
    input  wire        sel_in,
    input  wire        up_in,
    input  wire        down_in,

    // Outputs
    output wire [4:0]  h_out,
    output wire [5:0]  m_out,
    output wire [5:0]  s_out
);

    //---------------------------------
    // Internal signals
    //---------------------------------
    // reset_sync
    wire rstn_sync;

    // freq_divider
    wire clk_en_10khz;
    wire pulse_1hz;

    // sel_cond
    wire sel_pulse;
    wire sel_stable;

    // up_down_cond
    wire up_pulse;
    wire down_pulse;

    // sel_fsm
    wire [1:0] fsm_state;
    wire       fsm_adjust;
    wire       fsm_confirm;
    wire       fsm_timeout;

    // main_counter
    wire [4:0] main_hour;
    wire [5:0] main_min;
    wire [5:0] main_sec;

    // adjust_counter
    wire [4:0] shd_hour;
    wire [5:0] shd_min;
    wire [5:0] shd_sec;

    // control_mux
    wire        load_en;
    wire [16:0] load_data;
    wire        load_shd_en;
    wire [16:0] load_shd_data;
    wire        clear_shd;



    //---------------------------------------------------------
    // Instance modules
    //---------------------------------------------------------

    // reset_sync
    reset_sync u_reset_sync (
        .clk           (clk),
        .rstn          (rstn),
        .rstn_sync     (rstn_sync)
    );


    // freq_divider
    freq_divider u_freq_divider (
        .clk           (clk),
        .rstn_sync     (rstn_sync),
        .clk_en_10khz  (clk_en_10khz),
        .pulse_1hz     (pulse_1hz)
    );


    // sel_cond (in_sel_cond)
    sel_cond u_in_sel_cond (
        .clk           (clk),
        .rstn_sync     (rstn_sync),
        .clk_en_10khz  (clk_en_10khz),
        .button_in     (sel_in),
        .pulse_out     (sel_pulse),
        .stable_out    (sel_stable)
    );


    // up_down_cond (in_up_cond)
    up_down_cond u_in_up_cond (
        .clk           (clk),
        .rstn_sync     (rstn_sync),
        .clk_en_10khz  (clk_en_10khz),
        .button_in     (up_in),
        .pulse_out     (up_pulse)
    );


    // up_down_cond (in_down_cond)
    up_down_cond u_in_down_cond (
        .clk           (clk),
        .rstn_sync     (rstn_sync),
        .clk_en_10khz  (clk_en_10khz),
        .button_in     (down_in),
        .pulse_out     (down_pulse)
    );


    // sel_fsm
    sel_fsm u_sel_fsm (
        .clk           (clk),
        .rstn_sync     (rstn_sync),
        .clk_en_10khz  (clk_en_10khz),
        .sel_pulse     (sel_pulse),
        .sel_stable    (sel_stable),
        .up_pulse      (up_pulse),
        .down_pulse    (down_pulse),
        .fsm_state     (fsm_state),
        .fsm_adjust    (fsm_adjust),
        .fsm_confirm   (fsm_confirm),
        .fsm_timeout   (fsm_timeout)
    );


    // main_counter
    main_counter u_main_counter (
        .clk           (clk),
        .rstn_sync     (rstn_sync),
        .clk_en_10khz  (clk_en_10khz),
        .pulse_1hz     (pulse_1hz),
        .load_en       (load_en),
        .load_data     (load_data),
        .main_hour     (main_hour),
        .main_min      (main_min),
        .main_sec      (main_sec)
    );


    // adjust_counter
    adjust_counter u_adjust_counter (
        .clk           (clk),
        .rstn_sync     (rstn_sync),
        .clk_en_10khz  (clk_en_10khz),
        .fsm_state     (fsm_state),
        .up_pulse      (up_pulse),
        .down_pulse    (down_pulse),
        .load_shd_en   (load_shd_en),
        .load_shd_data (load_shd_data),
        .clear_shd     (clear_shd),
        .shd_hour      (shd_hour),
        .shd_min       (shd_min),
        .shd_sec       (shd_sec)
    );


    // control_mux
    control_mux u_control_mux (
        .clk           (clk),
        .rstn_sync     (rstn_sync),
        .clk_en_10khz  (clk_en_10khz),
        .fsm_state     (fsm_state),
        .fsm_adjust    (fsm_adjust),
        .fsm_confirm   (fsm_confirm),
        .fsm_timeout   (fsm_timeout),
        .main_hour     (main_hour),
        .main_min      (main_min),
        .main_sec      (main_sec),
        .shd_hour      (shd_hour),
        .shd_min       (shd_min),
        .shd_sec       (shd_sec),
        .load_en       (load_en),
        .load_data     (load_data),
        .load_shd_en   (load_shd_en),
        .load_shd_data (load_shd_data),
        .clear_shd     (clear_shd),
        .h_out         (h_out),
        .m_out         (m_out),
        .s_out         (s_out)
    );

endmodule