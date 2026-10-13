module reset_sync (
    input wire clk,
    input wire rst_n,
    output reg reset
);
 
    // =========================================================================
    // 1. INTERNAL SIGNALS
    // =========================================================================
    reg  rst_meta;


    // =========================================================================
    // 2. RESET SYNCHRONIZER LOGIC (2-STAGE FLIP-FLOP)
    // =========================================================================
    // Synchronizes the asynchronous active-low reset (rst_n) to the clock domain
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_meta <= 1'b0; 
            reset    <= 1'b0; 
        end else begin
            rst_meta <= 1'b1; 
            reset    <= rst_meta; 
        end
    end

endmodule