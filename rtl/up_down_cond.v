module up_down_cond #(
    parameter integer P_DEBOUNCE = 100   // 10ms
)(
    // Clock and Reset
    input  wire clk,
    input  wire rstn_sync,

    // Input from freq_divider
    input  wire clk_en_10khz,

    // Input from top
    input  wire button_in,

    // Output
    output wire pulse_out
);

    //------------------------------------------------------------------
    // Internal signals
    //------------------------------------------------------------------
    // 2-FF Synchronizer
    reg meta_button;              // May be metastable at async input edge
    reg synced;                   // Output of synchronizer

    // Debounce Counter
    reg [6:0] deb_count;
    reg       stabled;            // Debounced stable level

    // Rising Edge Detector
    reg delay;                    // stabled delayed by 1 cycle


    //------------------------------------------------------------------
    // Sequential
    //------------------------------------------------------------------
    // 2-FF Synchronizer
    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin
            meta_button <= 1'b0;
            synced      <= 1'b0;
        end
        else begin
            meta_button <= button_in;
            synced      <= meta_button;
        end
    end


    // Debounce Counter
    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin
            stabled   <= 1'b0;
            deb_count <= 7'd0;
        end
        else if (synced != stabled) begin
            if (clk_en_10khz) begin
                if (deb_count >= P_DEBOUNCE - 1) begin
                    stabled   <= synced;
                    deb_count <= 7'd0;
                end
                else begin
                    deb_count <= deb_count + 1'b1;
                end
            end
            else begin
                deb_count <= deb_count;
            end
        end
        else begin
            deb_count <= 7'd0;
        end
    end


    // Rising Edge Detector
    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin
            delay <= 1'b0;
        end
        else if (clk_en_10khz) begin
            delay <= stabled;
        end
        else begin
            delay <= delay;
        end
    end


    // Output
    assign pulse_out = stabled & ~delay;   // Pulse at rising edge

endmodule