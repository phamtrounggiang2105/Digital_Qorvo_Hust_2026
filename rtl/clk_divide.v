module clk_divide (
    input  wire clk_in,        // 1 MHz clock input
    input  wire rst_n,         // Active-low asynchronous reset
    output reg  pulse_1khz,    // 1-cycle pulse every 1 ms
    output reg  pulse_1hz      // 1-cycle pulse every 1 s
);

    // =========================================================================
    // 1. COUNTERS & TICK GENERATION WIRES
    // =========================================================================
    reg [9:0] cnt_us;   // 0..999: counts clock cycles -> 1 ms interval
    reg [9:0] cnt_ms;   // 0..999: counts milliseconds -> 1 s interval

    // Intermediate tick generators
    wire tick_ms = (cnt_us == 10'd999);
    wire tick_s  = tick_ms & (cnt_ms == 10'd999);


    // =========================================================================
    // 2. MICROSECOND COUNTER (1 MHz to 1 kHz)
    // =========================================================================
    // Counts clock cycles to generate a 1 ms tick
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            cnt_us <= 10'd0;
        else if (tick_ms)
            cnt_us <= 10'd0;
        else
            cnt_us <= cnt_us + 1'b1;
    end


    // =========================================================================
    // 3. MILLISECOND COUNTER (1 kHz to 1 Hz)
    // =========================================================================
    // Counts millisecond ticks to generate a 1 s tick
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            cnt_ms <= 10'd0;
        else if (tick_s)
            cnt_ms <= 10'd0;
        else if (tick_ms)
            cnt_ms <= cnt_ms + 1'b1;
    end


    // =========================================================================
    // 4. OUTPUT PULSE REGISTERS
    // =========================================================================
    // Registers to output 1-cycle pulse signals
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            pulse_1khz <= 1'b0;
            pulse_1hz  <= 1'b0;
        end else begin
            pulse_1khz <= tick_ms;
            pulse_1hz  <= tick_s;
        end
    end

endmodule
