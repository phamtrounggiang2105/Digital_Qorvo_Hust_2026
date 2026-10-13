module hour (
    input  wire        gclk,
    input  wire        rst_n,
    input  wire [5:0]  sec_rt,
    input  wire [5:0]  min_rt,
    input  wire        load_en,
    input  wire [4:0]  load_val,
    output reg  [4:0]  hour_rt
);

    // =========================================================================
    // 1. HOUR COUNTER LOGIC
    // =========================================================================
    always @(posedge gclk or negedge rst_n) begin
        if (!rst_n)       
            hour_rt <= 5'd0;
        else if (load_en) 
            // Load edited hour value when exiting edit mode
            hour_rt <= load_val;
        else if (sec_rt == 6'd59 && min_rt == 6'd59)
            // Increment hour when minutes and seconds roll over to 59; wrap around at 23
            hour_rt <= (hour_rt == 5'd23) ? 5'd0 : hour_rt + 1'b1;
    end

endmodule