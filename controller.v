module controller (
    input wire       clk,
    input wire       rst_n,
    input wire [1:0] current_state,
    input wire       sel_tick,
    input wire       up_tick,
    input wire       down_tick,
    input wire       timeout_5s,

    output wire      update_en
); 
    wire state_sec;         // state_sec == 2'b11
    wire state_not_normal;  // state_not_normal != 2'b00
    wire enable;            // execution mode
//comparator second and ~normal
    assign state_sec = current_state == 2'b11;
    assign state_not_normal = current_state != 2'b00;
    
    assign enable = state_not_normal & (up_tick ^ down_tick); // change data
//finish_logic: reset -> normal
    always @(*) begin
        if (timeout_5s || (state_sec & sel_tick)) begin
            finish <= 1'b1;
        end else begin
            finish <= 1'b0;
        end
    end
//change
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            changed <= 1'b0;
        end else if (finish) begin
            changed <= 1'b0;
        end else if (enable) begin
            changed <= 1'b1;
            if (enable) begin
                update_en <= 1'b1;
            end
        end
    end
    
    assign update_en = changed & finish;
endmodule
