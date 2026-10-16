module sel_fsm #(
    parameter integer P_LONG_PRESS_THRESHOLD = 30000,   // 30000 x 100us = 3s
    parameter integer P_TIMEOUT_THRESHOLD    = 50000    // 50000 x 100us = 5s
)(
    // Clock and Reset from Top
    input  wire       clk,
    input  wire       rstn_sync,

    // Input from freq_divider
    input  wire       clk_en_10khz,

    // Inputs from sel_cond
    input  wire       sel_pulse,
    input  wire       sel_stable,

    // Inputs from up_down_cond
    input  wire       up_pulse,
    input  wire       down_pulse,

    // Outputs
    output wire [1:0] fsm_state,
    output wire       fsm_adjust,
    output wire       fsm_confirm,
    output wire       fsm_timeout
);

    //---------------------------------------------------------------
    // Local parameters
    //---------------------------------------------------------------
    localparam [1:0] PL_NORMAL   = 2'b00;
    localparam [1:0] PL_SEL_MIN  = 2'b01;
    localparam [1:0] PL_SEL_HOUR = 2'b10;
    localparam [1:0] PL_SEL_SEC  = 2'b11;


    //---------------------------------------------------------------
    // Internal signals
    //---------------------------------------------------------------
    reg  [1:0] state;             // Current FSM state
    reg [15:0] inter_counter;     // Shared counter for long press and timeout
    reg        inter_adjust;      // Pulse when NORMAL transitions to SEL_MIN
    reg        inter_confirm;     // Pulse when SEL_SEC transitions to NORMAL
    reg        inter_timeout;     // Pulse when timeout occurs
    wire       activity;          // Any button activity

    assign activity = sel_pulse | up_pulse | down_pulse;


    //---------------------------------------------------------------
    // Sequential
    //---------------------------------------------------------------
    // State transition and Counter update
    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin
            state         <= PL_NORMAL;
            inter_counter <= 16'd0;
        end
        else if (clk_en_10khz) begin
            case (state)
                // NORMAL: counter serves long press detection
                PL_NORMAL: begin
                    if (sel_stable == 1'b0) begin
                        // Button not pressed or released, reset counter
                        inter_counter <= 16'd0;
                        state         <= state;
                    end
                    else if (inter_counter >= P_LONG_PRESS_THRESHOLD - 1) begin
                        // Long press detected, enter adjust mode
                        state         <= PL_SEL_MIN;
                        inter_counter <= 16'd0;
                    end
                    else begin
                        // Counting long press
                        inter_counter <= inter_counter + 1'b1;
                        state         <= state;
                    end
                end

                // SEL_MIN: counter serves timeout detection
                PL_SEL_MIN: begin
                    if (sel_pulse) begin
                        // Short press, move to next field
                        state         <= PL_SEL_HOUR;
                        inter_counter <= 16'd0;
                    end
                    else if (activity) begin
                        // Any button activity, reset timeout
                        inter_counter <= 16'd0;
                        state         <= state;
                    end
                    else if (inter_counter >= P_TIMEOUT_THRESHOLD - 1) begin
                        // Timeout, return to NORMAL
                        state         <= PL_NORMAL;
                        inter_counter <= 16'd0;
                    end
                    else begin
                        // Counting timeout
                        inter_counter <= inter_counter + 1'b1;
                        state         <= state;
                    end
                end

                // SEL_HOUR: counter serves timeout detection
                PL_SEL_HOUR: begin
                    if (sel_pulse) begin
                        state         <= PL_SEL_SEC;
                        inter_counter <= 16'd0;
                    end
                    else if (activity) begin
                        inter_counter <= 16'd0;
                        state         <= state;
                    end
                    else if (inter_counter >= P_TIMEOUT_THRESHOLD - 1) begin
                        state         <= PL_NORMAL;
                        inter_counter <= 16'd0;
                    end
                    else begin
                        inter_counter <= inter_counter + 1'b1;
                        state         <= state;
                    end
                end

                // SEL_SEC: counter serves timeout detection
                PL_SEL_SEC: begin
                    if (sel_pulse) begin
                        // Short press, confirm all adjustments
                        state         <= PL_NORMAL;
                        inter_counter <= 16'd0;
                    end
                    else if (activity) begin
                        inter_counter <= 16'd0;
                        state         <= state;
                    end
                    else if (inter_counter >= P_TIMEOUT_THRESHOLD - 1) begin
                        state         <= PL_NORMAL;
                        inter_counter <= 16'd0;
                    end
                    else begin
                        inter_counter <= inter_counter + 1'b1;
                        state         <= state;
                    end
                end

                default: begin
                    state         <= PL_NORMAL;
                    inter_counter <= 16'd0;
                end
            endcase
        end
        else begin
            // Hold when clk_en_10khz is low
            state         <= state;
            inter_counter <= inter_counter;
        end
    end


    //---------------------------------------------------------------
    // Sequential
    //---------------------------------------------------------------
    // Output pulses based on current state and conditions
    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin
            inter_adjust  <= 1'b0;
            inter_confirm <= 1'b0;
            inter_timeout <= 1'b0;
        end
        else if (clk_en_10khz) begin 
            case (state)
                // NORMAL: fire adjust pulse when long press threshold reached
                PL_NORMAL: begin
                    if (sel_stable && (inter_counter >= P_LONG_PRESS_THRESHOLD - 1)) begin
                        inter_adjust  <= 1'b1;
                        inter_confirm <= 1'b0;
                        inter_timeout <= 1'b0;
                    end
                    else begin
                        inter_adjust  <= 1'b0;
                        inter_confirm <= 1'b0;
                        inter_timeout <= 1'b0;
                    end
                end

                // SEL_MIN: fire timeout pulse when timeout threshold reached
                PL_SEL_MIN: begin
                    if (!activity && (inter_counter >= P_TIMEOUT_THRESHOLD - 1)) begin
                        inter_adjust  <= 1'b0;
                        inter_confirm <= 1'b0;
                        inter_timeout <= 1'b1;
                    end
                    else begin
                        inter_adjust  <= 1'b0;
                        inter_confirm <= 1'b0;
                        inter_timeout <= 1'b0;
                    end
                end

                // SEL_HOUR: fire timeout pulse when timeout threshold reached
                PL_SEL_HOUR: begin
                    if (!activity && (inter_counter >= P_TIMEOUT_THRESHOLD - 1)) begin
                        inter_adjust  <= 1'b0;
                        inter_confirm <= 1'b0;
                        inter_timeout <= 1'b1;
                    end
                    else begin
                        inter_adjust  <= 1'b0;
                        inter_confirm <= 1'b0;
                        inter_timeout <= 1'b0;
                    end
                end

                // SEL_SEC: fire confirm pulse on sel_pulse, timeout pulse on threshold
                PL_SEL_SEC: begin
                    if (sel_pulse) begin
                        inter_adjust  <= 1'b0;
                        inter_confirm <= 1'b1;
                        inter_timeout <= 1'b0;
                    end
                    else if (!activity && (inter_counter >= P_TIMEOUT_THRESHOLD - 1)) begin
                        inter_adjust  <= 1'b0;
                        inter_confirm <= 1'b0;
                        inter_timeout <= 1'b1;
                    end
                    else begin
                        inter_adjust  <= 1'b0;
                        inter_confirm <= 1'b0;
                        inter_timeout <= 1'b0;
                    end
                end

                default: begin
                    inter_adjust  <= 1'b0;
                    inter_confirm <= 1'b0;
                    inter_timeout <= 1'b0;
                end
            endcase
        end
        else begin
            inter_adjust  <= inter_adjust;
            inter_confirm <= inter_confirm;
            inter_timeout <= inter_timeout;
        end
    end


    // Outputs
    assign fsm_state   = state;
    assign fsm_adjust  = inter_adjust;
    assign fsm_confirm = inter_confirm;
    assign fsm_timeout = inter_timeout;

endmodule