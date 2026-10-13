module double_click #(
    parameter integer WINDOW_MS = 300
) (
    input wire clk,
    input wire rst_n,
    input wire tick_1khz,
    input wire normal,
    input wire sel_tick,
    output reg sel_double_tick
);
    localparam integer CW = (WINDOW_MS > 1) ? $clog2(WINDOW_MS) : 1;
    localparam [CW-1:0] LAST = WINDOW_MS - 1;
    reg [CW-1:0] count;
    reg value_flag;
    wire expired = tick_1khz & (count == LAST);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
            value_flag <= 1'b0;
            sel_double_tick <= 1'b0;
        end else begin
            sel_double_tick <= 1'b0;
            if (!normal) begin
                count <= 0;
                value_flag <= 1'b0;
            end else if (!value_flag) begin
                count <= 0;
                if (sel_tick)
                    value_flag <= 1'b1;
            end else if (expired || sel_tick) begin
                count <= 0;
                value_flag <= 1'b0;
                if (!expired && sel_tick)
                    sel_double_tick <= 1'b1;
            end else if (tick_1khz) begin
                count <= count + 1'b1;
            end
        end
    end
endmodule
