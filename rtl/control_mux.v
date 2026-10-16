module control_mux (
    // Clock and Reset
    input  wire        clk,
    input  wire        rstn_sync,

    // Input from freq_divider
    input  wire        clk_en_10khz,

    // Inputs from sel_fsm
    input  wire [1:0]  fsm_state,
    input  wire        fsm_adjust,
    input  wire        fsm_confirm,
    input  wire        fsm_timeout,

    // Inputs from main_counter
    input  wire [4:0]  main_hour,
    input  wire [5:0]  main_min,
    input  wire [5:0]  main_sec,

    // Inputs from adjust_counter
    input  wire [4:0]  shd_hour,
    input  wire [5:0]  shd_min,
    input  wire [5:0]  shd_sec,

    // Outputs to main_counter
    output wire        load_en,
    output wire [16:0] load_data,

    // Outputs to adjust_counter
    output wire        load_shd_en,
    output wire [16:0] load_shd_data,
    output wire        clear_shd,

    // Outputs top
    output wire [4:0]  h_out,
    output wire [5:0]  m_out,
    output wire [5:0]  s_out
);

    //--------------------------------------------------------
    // Local parameters
    //--------------------------------------------------------
    localparam [1:0] PL_NORMAL = 2'b00;


    //--------------------------------------------------------
    // Internal signals
    //--------------------------------------------------------
    reg [1:0] fsm_state_d;        // fsm_state delayed by 1 cycle for glitch-free MUX


    //--------------------------------------------------------
    // Sequential
    //--------------------------------------------------------
    // Delay fsm_state by 1 cycle
    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin
            fsm_state_d <= PL_NORMAL;
        end
        else if (clk_en_10khz) begin
            fsm_state_d <= fsm_state;
        end
    end


    //--------------------------------------------------------
    // Combinational
    //--------------------------------------------------------
    // Load adjust when entering adjust mode
    assign load_shd_en   = fsm_adjust;
    assign load_shd_data = {main_hour, main_min, main_sec};

    // Load main when confirm
    assign load_en       = fsm_confirm;
    assign load_data     = {shd_hour, shd_min, shd_sec};

    // Clear adjust when timeout
    assign clear_shd     = fsm_timeout;


    // Output to top 
    assign h_out = (fsm_state_d == PL_NORMAL) ? main_hour : shd_hour;
    assign m_out = (fsm_state_d == PL_NORMAL) ? main_min  : shd_min;
    assign s_out = (fsm_state_d == PL_NORMAL) ? main_sec  : shd_sec;

endmodule