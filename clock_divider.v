module clock_divider #(
    parameter integer P_DIV_1KHZ = 1000,
    parameter integer P_DIV_1HZ  = 1000
)(
    input wire clk,
    input wire rst_n,

    output reg tick_1khz,
    output reg tick_1hz
);

    reg [9:0] count_1khz;
    reg [9:0] count_1hz;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_1khz <= 10'd0;
            tick_1khz  <= 1'b0;
        end else begin
            if (count_1khz == P_DIV_1KHZ - 1) begin
                count_1khz <= 10'd0;
                tick_1khz  <= 1'b1;
            end else begin
                count_1khz <= count_1khz + 10'd1;
                tick_1khz  <= 1'b0;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_1hz <= 10'd0;
            tick_1hz  <= 1'b0;
        end else begin
            tick_1hz <= 1'b0;

            if (count_1khz == P_DIV_1KHZ - 1) begin
                if (count_1hz == P_DIV_1HZ - 1) begin
                    count_1hz <= 10'd0;
                    tick_1hz  <= 1'b1;
                end else begin
                    count_1hz <= count_1hz + 10'd1;
                end
            end
        end
    end

endmodule