module edit_time (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [5:0] s_rt,
    input  wire [5:0] m_rt,
    input  wire [4:0] h_rt,
    input  wire       fsm_normal,
    input  wire       fsm_edit_en_sec,
    input  wire       fsm_edit_en_min,
    input  wire       fsm_edit_en_hour,
    input  wire       button_down_press_sec,
    input  wire       button_down_press_min,
    input  wire       button_down_press_hour,
    input  wire       button_up_press_sec,
    input  wire       button_up_press_min,
    input  wire       button_up_press_hour,
    output wire [5:0] s_out,
    output wire [5:0] m_out,
    output wire [4:0] h_out,
    output reg        edited                 // Flag: indicates time was modified during the edit session
);

    // =========================================================================
    // 1. LOCAL SIGNALS & EDIT REGISTERS
    // =========================================================================
    reg [5:0] s_edit;
    reg [5:0] m_edit;
    reg [4:0] h_edit;
    reg       fsm_normal_d;

    // Multiplex outputs based on FSM mode (Normal mode vs. Edit mode)
    assign s_out = fsm_normal ? s_rt : s_edit;
    assign m_out = fsm_normal ? m_rt : m_edit;
    assign h_out = fsm_normal ? h_rt : h_edit;


    // =========================================================================
    // 2. MODE TRANSITION DETECTION
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) fsm_normal_d <= 1'b1;
        else        fsm_normal_d <= fsm_normal;
    end

    // Detect falling edge of fsm_normal (transitioning from normal mode to edit mode)
    wire enter_edit = fsm_normal_d & ~fsm_normal;


    // =========================================================================
    // 3. TIME EDIT LOGIC (INCREMENT / DECREMENT / CAPTURE)
    // =========================================================================
    // Edit register: captures realtime values once upon entering edit mode, then updates via button presses
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_edit <= 6'd0;
            m_edit <= 6'd0;
            h_edit <= 5'd0;
        end else if (enter_edit) begin
            s_edit <= s_rt;
            m_edit <= m_rt;
            h_edit <= h_rt;
        end else if (!fsm_normal) begin
            // Edit seconds
            if (fsm_edit_en_sec) begin
                if (button_down_press_sec)
                    s_edit <= (s_edit == 6'd0)  ? 6'd59 : s_edit - 1'b1;
                else if (button_up_press_sec)
                    s_edit <= (s_edit == 6'd59) ? 6'd0  : s_edit + 1'b1;
            end
            // Edit minutes
            if (fsm_edit_en_min) begin
                if (button_down_press_min)
                    m_edit <= (m_edit == 6'd0)  ? 6'd59 : m_edit - 1'b1;
                else if (button_up_press_min)
                    m_edit <= (m_edit == 6'd59) ? 6'd0  : m_edit + 1'b1;
            end
            // Edit hours
            if (fsm_edit_en_hour) begin
                if (button_down_press_hour)
                    h_edit <= (h_edit == 5'd0)  ? 5'd23 : h_edit - 1'b1;
                else if (button_up_press_hour)
                    h_edit <= (h_edit == 5'd23) ? 5'd0  : h_edit + 1'b1;
            end
        end
    end


    // =========================================================================
    // 4. EDITED STATUS FLAG LOGIC
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)         edited <= 1'b0;
        else if (enter_edit) edited <= 1'b0;
        else if (!fsm_normal &&
                 ((fsm_edit_en_sec  & (button_up_press_sec  | button_down_press_sec )) |
                  (fsm_edit_en_min  & (button_up_press_min  | button_down_press_min )) |
                  (fsm_edit_en_hour & (button_up_press_hour | button_down_press_hour))))
            edited <= 1'b1;
    end

endmodule