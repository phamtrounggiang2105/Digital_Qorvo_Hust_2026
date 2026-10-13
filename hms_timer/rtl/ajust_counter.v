module adjust_counter (
    // Clock and Reset
    input  wire        clk,
    input  wire        rstn_sync,

    // Input from freq_divider
    input  wire        clk_en_10khz,

    // Input from sel_fsm
    input  wire [1:0]  fsm_state,

    // Inputs from up_down_cond
    input  wire        up_pulse,
    input  wire        down_pulse,

    // Inputs from control_mux
    input  wire        load_shd_en,
    input  wire [16:0] load_shd_data,
    input  wire        clear_shd,

    // Output
    output wire [4:0]  shd_hour,
    output wire [5:0]  shd_min,
    output wire [5:0]  shd_sec
);

    //------------------------------------------------------------
    // Local parameters
    //------------------------------------------------------------
    localparam [1:0] PL_NORMAL   = 2'b00;
    localparam [1:0] PL_SEL_MIN  = 2'b01;
    localparam [1:0] PL_SEL_HOUR = 2'b10;
    localparam [1:0] PL_SEL_SEC  = 2'b11;


    //----------------------------------------------------------
    // Internal signals
    //----------------------------------------------------------
    reg [5:0] sec;                // Second register
    reg [5:0] min;                // Minute register
    reg [4:0] hour;               // Hour register

    wire [1:0] action;            // Up/Down common action
    wire [1:0] sec_adj;           // Action routed to sec
    wire [1:0] min_adj;           // Action routed to min
    wire [1:0] hour_adj;          // Action routed to hour


    //----------------------------------------------------------
    // Combinational (fsm decoder)
    //----------------------------------------------------------
    // Up has priority over Down
    assign action = up_pulse   ? 2'b01 :
                    down_pulse ? 2'b10 :
                                 2'b00;

    // Route action to the field under adjustment based on fsm_state
    assign sec_adj  = (fsm_state == PL_SEL_SEC)  ? action : 2'b00;
    assign min_adj  = (fsm_state == PL_SEL_MIN)  ? action : 2'b00;
    assign hour_adj = (fsm_state == PL_SEL_HOUR) ? action : 2'b00;


    //----------------------------------------------------------
    // Sequential
    //----------------------------------------------------------
    // SEC register
    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin
            sec <= 6'd0;
        end
        else if (clk_en_10khz) begin
            if (clear_shd) begin
                // Clear on timeout
                sec <= 6'd0;
            end
            else if (load_shd_en) begin
                sec <= load_shd_data[5:0];
            end
            else begin
                case (sec_adj)
                    2'b01:   sec <= (sec == 6'd59) ? 6'd0  : sec + 1'b1;
                    2'b10:   sec <= (sec == 6'd0)  ? 6'd59 : sec - 1'b1;
                    default: sec <= sec;
                endcase
            end
        end
    end


    // MIN register
    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin
            min <= 6'd0;
        end
        else if (clk_en_10khz) begin
            if (clear_shd) begin
                min <= 6'd0;
            end
            else if (load_shd_en) begin
                min <= load_shd_data[11:6];
            end
            else begin
                case (min_adj)
                    2'b01:   min <= (min == 6'd59) ? 6'd0  : min + 1'b1;
                    2'b10:   min <= (min == 6'd0)  ? 6'd59 : min - 1'b1;
                    default: min <= min;
                endcase
            end
        end
    end


    // HOUR register
    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin
            hour <= 5'd0;
        end
        else if (clk_en_10khz) begin
            if (clear_shd) begin
                hour <= 5'd0;
            end
            else if (load_shd_en) begin
                hour <= load_shd_data[16:12];
            end
            else begin
                case (hour_adj)
                    2'b01:   hour <= (hour == 5'd23) ? 5'd0  : hour + 1'b1;
                    2'b10:   hour <= (hour == 5'd0)  ? 5'd23 : hour - 1'b1;
                    default: hour <= hour;
                endcase
            end
        end
    end


    // Output
    assign shd_hour = hour;
    assign shd_min  = min;
    assign shd_sec  = sec;

endmodule