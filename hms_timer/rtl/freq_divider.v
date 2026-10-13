module freq_divider (
    // Clock and Reset
    input  wire clk,
    input  wire rstn,

    // Output
    output wire clk_en_10khz,
    output wire pulse_1hz
);

    //----------------------------------------------------------
    // Internal signals
    //----------------------------------------------------------
    reg [6:0] count_10khz;      
    reg       inter_10khz;      // Pulse 1 cycle 10khz
    reg [13:0] count_1hz;       
    reg        inter_1hz;        // Pulse 1 cycle 1s


    //----------------------------------------------------------
    // Sequential
    //---------------------------------------------------------
    // clk_en_10khz
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            count_10khz <= 7'd0;
            inter_10khz <= 1'b0;
        end 
        else if (count_10khz == 7'd99) begin
            count_10khz <= 7'd0;
            inter_10khz <= 1'b1;
        end 
        else begin
            count_10khz <= count_10khz + 1'b1;
            inter_10khz <= 1'b0;
        end
    end


    // pulse_1hz
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            count_1hz <= 14'd0;
            inter_1hz <= 1'b0;
        end 
        else if (inter_10khz) begin    // count_10khz == 7'd99;
            if (count_1hz == 14'd9999) begin
                count_1hz <= 14'd0;
                inter_1hz <= 1'b1;
            end 
            else begin
                count_1hz <= count_1hz + 1'b1;
                inter_1hz <= 1'b0;
            end
        end 
        else begin
            inter_1hz <= 1'b0;
        end
    end


    // Output
    assign clk_en_10khz = inter_10khz;
    assign pulse_1hz    = inter_1hz;

endmodule
