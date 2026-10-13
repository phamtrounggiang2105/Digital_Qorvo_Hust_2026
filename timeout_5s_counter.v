module timeout_5s_counter (
    input wire       clk,
    input wire       rst_n,
    input wire       tick_1hz,
    input wire [1:0] current_state,
    input wire       sel_tick,
    input wire       up_tick,
    input wire       down_tick,

    output reg       timeout_5s
);
    reg [2:0] count;
    wire counter_reset;
    wire counter_en;
    wire timeout_en;
// generate enable
    assign timeout_en = current_state != 2'b00;
    assign counter_en = tick_1hz & timeout_en;
// generate reset
    assign counter_reset = ~timeout_en | sel_tick | up_tick | down_tick;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count      <= 3'd0;
            timeout_5s <= 1'b0;
        end else if (counter_reset) begin
            count      <= 3'd0;
            timeout_5s <= 1'b0;
        end else if (counter_en) begin
            if (count == 3'd4) begin
                count      <= 3'd0;
                timeout_5s <= 1'b1;
            end else begin
                count      <= count + 3'b1;
                timeout_5s <= 1'b0; 
            end
        end
    end
endmodule
