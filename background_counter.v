module background_counter (
    input wire       clk,
    input wire       rst_n,
    input wire       tick_1hz,
    input wire       update_en,
    input wire [4:0] set_hour,
    input wire [5:0] set_min,
    input wire [5:0] set_sec,

    output reg [4:0] bg_hour,
    output reg [5:0] bg_min,
    output reg [5:0] bg_sec
);
    wire o_sec_i_min;
    wire o_min_i_hour;

    reg [4:0] next_hour;
    reg [5:0] next_min;
    reg [5:0] next_sec;

    assign o_sec_i_min = ~update_en & tick_1hz & (bg_sec == 6'd59);

    assign o_min_i_hour = o_sec_i_min
                       & (bg_min == 6'd59);

    always @(*) begin
        // default assignment (alwasys keep the current value)
        next_hour = bg_hour;
        next_min  = bg_min;
        next_sec  = bg_sec;
        if (update_en) begin
            next_hour = set_hour;
            next_min  = set_min;
            next_sec  = set_sec;
// second - flag: tick_1hz
        end else if (tick_1hz) begin
            if (bg_sec == 6'd59) begin
                next_sec = 6'd0;
            end else begin
                next_sec = bg_sec + 6'd1;
            end
// minute - flag: o_sec_i_min
            if (o_sec_i_min) begin
                if (bg_min == 6'd59) begin
                    next_min = 6'd0;
                end else begin
                    next_min = bg_min + 6'd1;
                end
            end
// hour - flag: o_min_i_hour
            if (o_min_i_hour) begin
                if (bg_hour == 5'd23) begin
                    next_hour = 5'd0;
                end else begin
                    next_hour = bg_hour + 5'd1;
                end
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bg_hour <= 5'd0;
            bg_min  <= 6'd0;
            bg_sec  <= 6'd0;
        end else begin
            bg_hour <= next_hour;
            bg_min  <= next_min;
            bg_sec  <= next_sec;
        end
    end

endmodule