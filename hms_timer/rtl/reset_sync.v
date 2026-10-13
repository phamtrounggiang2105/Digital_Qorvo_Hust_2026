module reset_sync (
    // Clock and Reset from top
    input  wire clk,
    input  wire rstn,

    // Output
    output wire rstn_sync
);

    //------------------------------------------------------------------
    // Internal signals
    //------------------------------------------------------------------
    reg meta_rstn;            // may be metastable on deassert edge
    reg inter_rstn_sync;      // clean synchronized reset


    //------------------------------------------------------------------
    // Sequential
    //------------------------------------------------------------------
    // 2-FF Reset Synchronizer: Async Assert, Sync Deassert
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            meta_rstn       <= 1'b0;
            inter_rstn_sync <= 1'b0;
        end
        else begin
            meta_rstn       <= 1'b1;
            inter_rstn_sync <= meta_rstn;
        end
    end


    // Output
    assign rstn_sync = inter_rstn_sync;

endmodule