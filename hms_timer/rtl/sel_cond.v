module sel_cond #( 
    parameter integer DEBOUNCE = 100 
)(
    // Clock and Reset
    input  wire clk,             
    input  wire rstn,             
    input  wire clk_en_10khz,     

    // Input from top
    input  wire raw_in,           

    // Output
    output wire pulse_out,        
    output wire stable_out       
);

    //-------------------------------------------------------------
    // Internal signals
    //-------------------------------------------------------------
    // 2-FF Synchronizer
    reg sync_ff1;           
    reg synced;                   // Output synchronizer  

    // Debounce Counter
    reg [6:0] deb_count;          
    reg       stabled;            // Giá trị ổn định sau debounce

    // Rising Edge Detector
    reg delay;                    // delay 1 cycle

    
    //---------------------------------------------------------------
    // Sequencer
    //--------------------------------------------------------------
    // 2-FF Synchronizer
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sync_ff1 <= 1'b0;
            synced   <= 1'b0;
        end 
        else begin
            sync_ff1 <= raw_in;
            synced   <= sync_ff1;
        end
    end


    // Debounce Counter 
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            stabled   <= 1'b0;
            deb_count <= 7'd0;
        end 
        else if (clk_en_10khz) begin
            if (synced != stabled) begin
                if (deb_count == DEBOUNCE - 1) begin
                    stabled   <= synced;
                    deb_count <= 7'd0;
                end 
                else begin
                    deb_count <= deb_count + 1'b1;
                end
            end 
            else begin
                deb_count <= 7'd0;
            end
        end
    end


    // Rising Edge Detector
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            delay <= 1'b0;
        else if (clk_en_10khz) begin
            delay <= stabled;
        end
        else begin
            delay <= delay;
        end
    end

    
    // Output
    assign pulse_out  = stabled & ~delay;   // Pulse
    assign stable_out = stabled;             // Level

endmodule
