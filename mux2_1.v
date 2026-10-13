module mux2_1 (
    input wire  [1:0] current_state,
    input wire  [4:0] bg_hour, 
    input wire  [5:0] bg_min,
    input wire  [5:0] bg_sec,

    input wire  [4:0] set_hour,
    input wire  [5:0] set_min,
    input wire  [5:0] set_sec,

    output wire [4:0] h_out,
    output wire [5:0] m_out, 
    output wire [5:0] s_out
);
    wire ctrl_state;
    assign ctrl_state = current_state != 2'b00;
    assign h_out = ctrl_state ? set_hour : bg_hour;
    assign m_out = ctrl_state ? set_min  : bg_min;
    assign s_out = ctrl_state ? set_sec  : bg_sec;
endmodule
