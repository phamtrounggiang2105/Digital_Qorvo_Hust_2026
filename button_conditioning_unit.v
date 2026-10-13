module button_conditioning_unit #(
    parameter integer DEBOUNCE_MS = 10,
    parameter integer DOUBLE_CLICK_MS = 300
) (
    input wire clk,
    input wire rst_n,
    input wire tick_1khz,
    input wire [1:0] current_state,
    input wire sel_in,
    input wire up_in,
    input wire down_in,
    output wire sel_tick,
    output wire up_tick,
    output wire down_tick,
    output wire sel_double_tick
);
    wire [2:0] btn_in = {down_in, up_in, sel_in};
    wire [2:0] btn_sync;
    wire [2:0] btn_db;
    wire [2:0] btn_tick;
    genvar i;

    assign {down_tick, up_tick, sel_tick} = btn_tick;

    generate
        for (i = 0; i < 3; i = i + 1) begin : g_button
            button_synchronizer u_sync (
                .clk(clk),
                .rst_n(rst_n),
                .btn_in(btn_in[i]),
                .btn_sync(btn_sync[i])
            );

            debounce_filter #(.DEBOUNCE_MS(DEBOUNCE_MS)) u_debounce (
                .clk(clk),
                .rst_n(rst_n),
                .tick_1khz(tick_1khz),
                .btn_sync(btn_sync[i]),
                .btn_db(btn_db[i])
            );

            edge_detector u_edge (
                .clk(clk),
                .rst_n(rst_n),
                .btn_db(btn_db[i]),
                .btn_tick(btn_tick[i])
            );
        end
    endgenerate

    double_click #(.WINDOW_MS(DOUBLE_CLICK_MS)) u_double_click (
        .clk(clk),
        .rst_n(rst_n),
        .tick_1khz(tick_1khz),
        .normal(current_state == 2'b00),
        .sel_tick(sel_tick),
        .sel_double_tick(sel_double_tick)
    );
endmodule
