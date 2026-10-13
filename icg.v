module icg (
    input  wire clk,    // Original 1 MHz master clock
    input  wire en,     // Enable signal (1 = allow clock pass-through)
    output wire gclk    // Gated clock output
);

    // =========================================================================
    // 1. INTERNAL SIGNALS
    // =========================================================================
    reg en_latch;


    // =========================================================================
    // 2. LATCH CONTROL LOGIC (NEGATIVE-LEVEL SENSITIVE)
    // =========================================================================
    // Transparent when clk is low; holds its value when clk is high to prevent glitches
    always @(clk or en or en_latch) begin
        if (!clk)
            en_latch = en;
    end


    // =========================================================================
    // 3. GATED CLOCK GENERATION
    // =========================================================================
    assign gclk = clk & en_latch;

endmodule