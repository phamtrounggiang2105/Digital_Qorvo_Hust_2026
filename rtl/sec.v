module sec (
    input  wire        gclk,
    input  wire        rst_n,
    input  wire        load_en,
    input  wire [5:0]  load_val,
    output reg  [5:0]  sec_rt
);

    // =========================================================================
    // 1. SECOND COUNTER LOGIC
    // =========================================================================
    always @(posedge gclk or negedge rst_n) begin
        if (!rst_n)       
            sec_rt <= 6'd0;
        else if (load_en) 
            // Load edited second value when exiting edit mode
            sec_rt <= load_val;
        else              
            // Increment seconds on each gated clock tick; wrap around at 59
            sec_rt <= (sec_rt == 6'd59) ? 6'd0 : sec_rt + 1'b1;
    end

endmodule
