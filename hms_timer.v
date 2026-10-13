module hms_timer #(
    parameter integer P_DIV_1KHZ           = 1000,
    parameter integer P_DIV_1HZ            = 1000,
    parameter integer P_DEBOUNCE_COUNT     = 10,
    parameter integer P_DOUBLE_CLICK_COUNT = 300
)(
    input wire       clk,
    input wire       rst_n,
    input wire       sel_in,
    input wire       up_in,
    input wire       down_in,

    output wire [4:0] h_out,
    output wire [5:0] m_out,
    output wire [5:0] s_out
);
    wire tick_1khz;
    wire tick_1hz;

    wire sel_tick;
    wire sel_double_tick;
    wire up_tick;
    wire down_tick;

    wire [1:0] current_state;
    wire       timeout_5s;
    wire       update_en;

    wire [4:0] bg_hour;
    wire [5:0] bg_min;
    wire [5:0] bg_sec;

    wire [4:0] set_hour;
    wire [5:0] set_min;
    wire [5:0] set_sec;

    clock_divider #(
        .P_DIV_1KHZ (P_DIV_1KHZ),
        .P_DIV_1HZ  (P_DIV_1HZ)
    ) u_clock_divider (
        .clk      (clk),
        .rst_n    (rst_n),
        .tick_1khz(tick_1khz),
        .tick_1hz (tick_1hz)
    );

    button_conditioning_unit #(
        .P_DEBOUNCE_COUNT     (P_DEBOUNCE_COUNT),
        .P_DOUBLE_CLICK_COUNT(P_DOUBLE_CLICK_COUNT)
    ) u_button (
        .clk            (clk),
        .rst_n          (rst_n),
        .tick_1khz      (tick_1khz),
        .current_state  (current_state),
        .sel_in         (sel_in),
        .up_in          (up_in),
        .down_in        (down_in),
        .sel_tick       (sel_tick),
        .sel_double_tick(sel_double_tick),
        .up_tick        (up_tick),
        .down_tick      (down_tick)
    );

    fsm u_fsm (
        .clk            (clk),
        .rst_n          (rst_n),
        .sel_tick       (sel_tick),
        .sel_double_tick(sel_double_tick),
        .timeout_5s     (timeout_5s),
        .current_state  (current_state)
    );

    timeout_5s_counter u_timeout_5s_counter (
        .clk          (clk),
        .rst_n        (rst_n),
        .tick_1hz     (tick_1hz),
        .current_state(current_state),
        .sel_tick     (sel_tick),
        .up_tick      (up_tick),
        .down_tick    (down_tick),
        .timeout_5s   (timeout_5s)
    );

    timer_counter u_timer_counter (
        .clk          (clk),
        .rst_n        (rst_n),
        .current_state(current_state),
        .sel_tick     (sel_tick),
        .up_tick      (up_tick),
        .down_tick    (down_tick),
        .timeout_5s   (timeout_5s),

        .bg_hour      (bg_hour),
        .bg_min       (bg_min),
        .bg_sec       (bg_sec),

        .h_out        (h_out),
        .m_out        (m_out),
        .s_out        (s_out),

        .set_hour     (set_hour),
        .set_min      (set_min),
        .set_sec      (set_sec),
        .update_en    (update_en)
    );

    background_counter u_background_counter (
        .clk      (clk),
        .rst_n    (rst_n),
        .tick_1hz (tick_1hz),
        .update_en(update_en),

        .set_hour (set_hour),
        .set_min  (set_min),
        .set_sec  (set_sec),

        .bg_hour  (bg_hour),
        .bg_min   (bg_min),
        .bg_sec   (bg_sec)
    );

endmodule