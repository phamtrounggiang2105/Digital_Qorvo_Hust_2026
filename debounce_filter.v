module debounce_filter #(
    parameter integer P_DEBOUNCE_COUNT = 10
)(
    input wire clk,
    input wire rst_n,
    input wire tick_1khz,
    input wire button_sync,

    output reg button_db
);

    reg [3:0] count;

    wire different;
    wire at_limit;
    wire accept;

    assign different = button_sync ^ button_db;
    assign at_limit  = count == P_DEBOUNCE_COUNT; // compare: count with P_DEBOUNCE_COUNT
    assign accept    = different & at_limit & tick_1khz;
// counter = P_DEBOUNCE_COUNT  
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 4'd0;
        end else if (!different) begin
            count <= 4'd0;
        end else if (tick_1khz) begin
            if (at_limit)
                count <= 4'd0;
            else
                count <= count + 4'd1;
        end
    end
// Dff
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            button_db <= 1'b0;
        end else if (accept) begin
            button_db <= button_sync;
        end
    end

endmodule