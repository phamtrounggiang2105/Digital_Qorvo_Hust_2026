module edge_detector (
    input wire clk,
    input wire rst_n,
    input wire button_db,

    output reg button_tick
);
    reg button_db_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            button_db_d <= 1'b0;
            button_tick <= 1'b0;
        end else begin
            button_db_d <= button_db;
            button_tick <= button_db & ~button_db_d;
        end
    end

endmodule