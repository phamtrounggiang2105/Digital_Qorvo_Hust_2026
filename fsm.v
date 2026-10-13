module fsm (
    input wire       clk,
    input wire       rst_n,
    input wire       sel_tick,
    input wire       sel_double_tick, 
    input wire       timeout_5s,
    output reg [1:0] current_state
);
    localparam [1:0] PL_NORMAL   = 2'b00;
    localparam [1:0] PL_SET_HOUR = 2'b01;
    localparam [1:0] PL_SET_MIN  = 2'b10;
    localparam [1:0] PL_SET_SEC  = 2'b11;
// enable signal for state transition
    wire enable;
    assign enable = sel_tick | timeout_5s;

    reg [1:0] next_state;

    always @(*) begin
        next_state = current_state;
        case (current_state)
            PL_NORMAL: begin 
                if (sel_double_tick) begin
                    next_state = PL_SET_HOUR; 
                end
            end
            PL_SET_HOUR: begin
                if (enable) begin
                    if (timeout_5s) begin
                        next_state = PL_NORMAL;
                    end
                    else begin
                        next_state = PL_SET_MIN;
                    end
                end
            end
            PL_SET_MIN: begin
                if (enable) begin
                    if (timeout_5s) begin
                        next_state = PL_NORMAL;
                    end
                    else begin
                        next_state = PL_SET_SEC;
                    end
                end
            end
            PL_SET_SEC: begin
                if (enable) begin
                    if (timeout_5s) begin
                        next_state = PL_NORMAL;
                    end
                    else begin
                        next_state = PL_SET_HOUR;
                    end
                end
            end
            default: next_state = PL_NORMAL;
        endcase
    end
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            current_state <= PL_NORMAL;
        end
        else begin
            current_state <= next_state;
        end
endmodule
