module button_synchronizer (
    input wire clk,
    input wire rst_n,
    input wire button_in,

    output wire button_sync
);

    reg meta_ff_1;
    reg meta_ff_2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            meta_ff_1 <= 1'b0;
            meta_ff_2 <= 1'b0;
        end else begin
            meta_ff_1 <= button_in;
            meta_ff_2 <= meta_ff_1;
        end
    end

    assign button_sync = meta_ff_2;

endmodule