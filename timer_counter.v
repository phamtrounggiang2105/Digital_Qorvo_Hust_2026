module timer_counter (
    input wire        clk,
    input wire        rst_n,
    input wire [1:0]  current_state,
    input wire        sel_tick, 
    input wire        up_tick, 
    input wire        down_tick, 
    input wire        timeout_5s,
    input wire [4:0]  bg_hour,
    input wire [5:0]  bg_min,
    input wire [5:0]  bg_sec,

    output wire [4:0] h_out, 
    output wire [5:0] m_out,
    output wire [5:0] s_out,

    output wire [4:0] set_hour,
    output wire [5:0] set_min,
    output wire [5:0] set_sec,

    output wire       update_en
);
    wire [4:0] set_hour;
    wire [5:0] set_min;
    wire [5:0] set_sec;

    controller u_controller (
        .clk(clk),
        .rst_n(rst_n),
        .current_state(current_state),
        .sel_tick(sel_tick), 
        .up_tick(up_tick), 
        .down_tick(down_tick),
        .timeout_5s(timeout_5s), 

        .update_en(update_en)
    );


    edit_value u_edit_value (
        .clk(clk),
        .rst_n(rst_n),
        .up_tick(up_tick), 
        .down_tick(down_tick),
        .current_state(current_state),
        .bg_hour(bg_hour), 
        .bg_min(bg_min), 
        .bg_sec(bg_sec),

        .set_hour(set_hour), 
        .set_min(set_min), 
        .set_sec(set_sec)
    );

    mux2_1 u_mux2_1 (
        .current_state(current_state),
        .bg_hour(bg_hour), 
        .bg_min(bg_min), 
        .bg_sec(bg_sec),
        .set_hour(set_hour), 
        .set_min(set_min), 
        .set_sec(set_sec),

        .h_out(h_out), 
        .m_out(m_out), 
        .s_out(s_out)
    );
endmodule
