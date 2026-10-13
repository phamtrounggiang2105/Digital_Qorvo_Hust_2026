module min (
    input  wire        gclk,
    input  wire        rst_n,
    input  wire [5:0]  sec_rt,        // Read-only reference, not a carry flag
    input  wire        load_en,
    input  wire [5:0]  load_val,
    output reg  [5:0]  min_rt
);

    // =========================================================================
    // 1. MINUTE COUNTER LOGIC
    // =========================================================================
    always @(posedge gclk or negedge rst_n) begin
        if (!rst_n)       
            min_rt <= 6'd0;
        else if (load_en) 
            // Load edited minute value when exiting edit mode
            min_rt <= load_val;
        else if (sec_rt == 6'd59)
            // Increment minute when seconds roll over to 59; wrap around at 59
            min_rt <= (min_rt == 6'd59) ? 6'd0 : min_rt + 1'b1;
    end

endmodule