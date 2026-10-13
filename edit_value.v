

module edit_value (
    input wire       clk, 
    input wire       rst_n,
    input wire       up_tick,
     input wire      down_tick,
    input wire [1:0] current_state,
    input wire [4:0] bg_hour,
    input wire [5:0] bg_min,
    input wire [5:0] bg_sec,

    output reg [4:0] edit_hour,
    output reg [5:0] edit_min,
    output reg [5:0] edit_sec
);
    wire      edit_mode;
    wire      capture;
    reg       edit_mode_d;
    reg [4:0] next_hour;
    reg [5:0] next_min;
    reg [5:0] next_sec;

// generate capture signals
    assign edit_mode = current_state != 2'b00;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            edit_mode_d <= 1'b0;
        end else begin
            edit_mode_d <= edit_mode;
        end
    end
    assign capture = edit_mode && !edit_mode_d;

// next_8 => counter_* => edit_*
    always @(*) begin
            edit_hour = next_hour;
            edit_min  = next_min;
            edit_sec  = next_sec;
        if (capture) begin
            next_hour = bg_hour;
            next_min  = bg_min;
            next_sec  = bg_sec;
        end else begin
            case (current_state)
                2'b01: begin
                    case (up_tick, down_tick)
                        2'b10: next_hour = (edit_hour == 5'd23) ? 5'd0 : edit_hour + 1'b1;
                        2'b01: next_hour = (edit_hour == 5'd0) ? 5'd23 : edit_hour - 1'b1;
                        default: next_hour = edit_hour;
                    endcase
                end
                2'b10: begin
                    case (up_tick, down_tick)
                        2'b10: next_min = (edit_min == 6'd59) ? 6'd0 : edit_min + 1'b1;
                        2'b01: next_min = (edit_min == 6'd0) ? 6'd59 : edit_min - 1'b1;
                        default: next_min = edit_min;
                    endcase
                end
                2'b11: begin
                    case (up_tick, down_tick)
                        2'b10: next_sec = (edit_sec == 6'd59) ? 6'd0 : edit_sec + 1'b1;
                        2'b01: next_sec = (edit_sec == 6'd0) ? 6'd59 : edit_sec - 1'b1;
                        default: next_sec = edit_sec;
                    endcase
                end
                default: begin end 
            endcase
        end
    end
// edit
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            edit_hour <= 5'd0;
            edit_min  <= 6'd0; 
            edit_sec  <= 6'd0;
        end else begin
            edit_hour <= next_hour;
            edit_min  <= next_min;
            edit_sec  <= next_sec;
        end
    end
endmodule
