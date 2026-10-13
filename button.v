module button (
    input  wire clk,                    // 1 MHz
    input  wire rst_n,
    input  wire pulse_1khz,             // 1-cycle pulse every 1 ms
    input  wire fsm_normal,             // 1: normal mode, 0: tuning mode
    input  wire sel_in,                 // Active-high button inputs
    input  wire up_in,                     // Active-high button inputs
    input  wire down_in,                   // Active-high button inputs
    output reg  btn_sel_press_fsm,  // 1-cycle pulse: state transition trigger
    output reg  btn_up_press,    // 1-cycle pulse: increment/decrement trigger
    output reg  btn_down_press,  // 1-cycle pulse: increment/decrement trigger
    output wire btn_act_fsm   //    1-cycle pulse: any button activity (sel/up/down)
);

    // =========================================================================
    // 1. LOCAL SIGNALS & TIMING CONFIGURATION
    // =========================================================================
    wire tick_1ms = pulse_1khz;     

    // Detect state transition of fsm_normal to reset debounce counters if needed
    reg normal_d;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) normal_d <= 1'b1;
        else        normal_d <= fsm_normal;
    end
    wire normal_change = fsm_normal ^ normal_d;

    // Dynamic thresholds for button debounce / hold duration
    wire [11:0] sel_thr = fsm_normal ? 12'd3000 : 12'd20; // 3s in normal, 20ms in tuning
    localparam [11:0] UD_THR = 12'd20;                     // 20ms threshold for UP/DOWN


    // =========================================================================
    // 2. SYNCHRONIZATION & DEBOUNCE REGISTERS
    // =========================================================================
    // Metastability reduction registers
    reg sel_meta; // Synchronizer for SELECT button
    reg sel_sync; // Debounced SELECT button signal
    reg up_meta;    // Synchronizer for UP button
    reg up_sync;  // Debounced UP button signal
    reg dn_meta;    // Synchronizer for DOWN button
    reg dn_sync; // Debounced DOWN button signal

    // Debounce/Timeout counters and one-shot flags
    reg [11:0] sel_cnt; 
    reg [11:0] up_cnt; 
    reg [11:0] dn_cnt;
    reg        sel_fired;  
    reg        up_fired;   
    reg        dn_fired;


    // =========================================================================
    // 3. SYNCHRONIZER, DEBOUNCER & FSM PUNCH LOGIC
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_meta <= 1'b0; 
            sel_sync <= 1'b0;
            up_meta  <= 1'b0; 
            up_sync  <= 1'b0;
            dn_meta  <= 1'b0; 
            dn_sync  <= 1'b0;
            sel_cnt  <= 12'd0; 
            up_cnt   <= 12'd0; 
            dn_cnt   <= 12'd0;
            sel_fired <= 1'b0; 
            up_fired  <= 1'b0; 
            dn_fired  <= 1'b0;
            btn_sel_press_fsm <= 1'b0;
            btn_up_press      <= 1'b0;
            btn_down_press    <= 1'b0;
        end else begin
            // Input synchronization (2-stage flip-flops)
            sel_meta <= sel_in;   
            sel_sync <= sel_meta;
            up_meta  <= up_in;    
            up_sync  <= up_meta;
            dn_meta  <= down_in;  
            dn_sync  <= dn_meta;

            // Default pulse outputs (1-cycle width)
            btn_sel_press_fsm <= 1'b0;
            btn_up_press      <= 1'b0;
            btn_down_press    <= 1'b0;

            // --- SELECT BUTTON DEBOUNCE & HOLD HANDLER ---
            if (!sel_sync) begin
                sel_cnt   <= 12'd0;
                sel_fired <= 1'b0;
            end else if (!sel_fired) begin
                if (normal_change)
                    sel_cnt <= 12'd0;
                else if (tick_1ms) begin
                    if (sel_cnt == sel_thr - 1'b1) begin
                        btn_sel_press_fsm <= 1'b1;
                        sel_fired         <= 1'b1;
                    end else
                        sel_cnt <= sel_cnt + 1'b1;
                end
            end

            // --- UP BUTTON DEBOUNCE & HOLD HANDLER ---
            if (!up_sync) begin
                up_cnt   <= 12'd0;
                up_fired <= 1'b0;
            end else if (!up_fired && tick_1ms) begin
                if (up_cnt == UD_THR - 1'b1) begin
                    btn_up_press <= 1'b1;
                    up_fired     <= 1'b1;
                end else
                    up_cnt <= up_cnt + 1'b1;
            end

            // --- DOWN BUTTON DEBOUNCE & HOLD HANDLER ---
            if (!dn_sync) begin
                dn_cnt   <= 12'd0;
                dn_fired <= 1'b0;
            end else if (!dn_fired && tick_1ms) begin
                if (dn_cnt == UD_THR - 1'b1) begin
                    btn_down_press <= 1'b1;
                    dn_fired       <= 1'b1;
                end else
                    dn_cnt <= dn_cnt + 1'b1;
            end
        end
    end


    // =========================================================================
    // 4. COMBINATIONAL OUTPUTS
    // =========================================================================
    assign btn_act_fsm = btn_sel_press_fsm | btn_up_press | btn_down_press;

endmodule