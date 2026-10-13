module fsm (
    input  wire clk,                    // 1 MHz clock
    input  wire rst_n,                  // Active-low asynchronous reset
    input  wire pulse_1hz,              // 1-cycle pulse every 1 s
    input  wire btn_sel_press_fsm,      // 1-cycle pulse: state transition trigger
    input  wire btn_act_fsm,            // 1-cycle pulse: any button activity (sel/up/down)
    input  wire edited,                 // Flag: time was modified in edit session (from edit_time, unused currently)
    output wire fsm_normal,             // Output state flags
    output wire fsm_edit_en_sec,
    output wire fsm_edit_en_min,
    output wire fsm_edit_en_hour,
    output wire fsm_load                // 1-cycle pulse: load edited values into real-time counter
);

    // =========================================================================
    // 1. LOCAL PARAMETERS & STATE ENCODING
    // =========================================================================
    localparam NORMAL = 2'd0,
               SEC    = 2'd1,
               MIN    = 2'd2,
               HOUR   = 2'd3;

    reg [1:0] state;
    reg [2:0] cnt;


    // =========================================================================
    // 2. INACTIVITY TIMEOUT COUNTER
    // =========================================================================
    // Counts seconds of user inactivity during edit mode
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 3'd0;
        else if (state == NORMAL || btn_act_fsm)
            cnt <= 3'd0;
        else if (pulse_1hz)
            cnt <= cnt + 1'b1;
    end

    // Timeout trigger: triggers only in edit modes to prevent false timeouts after returning to NORMAL
    wire timeout = (cnt == 3'd5) && (state != NORMAL);


    // =========================================================================
    // 3. FSM STATE TRANSITION LOGIC
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= NORMAL;
        else if (timeout)
            state <= NORMAL;
        else if (btn_sel_press_fsm) begin
            case (state)
                NORMAL: state <= SEC;
                SEC:    state <= MIN;
                MIN:    state <= HOUR;
                HOUR:   state <= NORMAL;
            endcase
        end
    end


    // =========================================================================
    // 4. COMBINATIONAL OUTPUTS
    // =========================================================================
    assign fsm_normal        = (state == NORMAL);
    assign fsm_edit_en_sec   = (state == SEC);
    assign fsm_edit_en_min   = (state == MIN);
    assign fsm_edit_en_hour = (state == HOUR);

    // Load signal pulses when exiting the edit sequence from HOUR state without timing out
    assign fsm_load = btn_sel_press_fsm && (state == HOUR) && !timeout;

endmodule
