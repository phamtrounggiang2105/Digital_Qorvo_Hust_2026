module main_counter (
    // Clock and Reset
    input  wire        clk,
    input  wire        rstn_sync,

    // Inputs from freq_divider
    input  wire        clk_en_10khz,
    input  wire        pulse_1hz,

    // Inputs from control_mux
    input  wire        load_en,
    input  wire [16:0] load_data,

    // Output
    output wire [4:0]  main_hour,
    output wire [5:0]  main_min,
    output wire [5:0]  main_sec
);

    //--------------------------------------------------------
    // Internal signals
    //--------------------------------------------------------
    reg [5:0] sec;                // Second register
    reg [5:0] min;                // Minute register
    reg [4:0] hour;               // Hour register

    wire sec_carry;               // Carry from sec to min
    wire min_carry;               // Carry from min to hour

    // Carry flags
    assign sec_carry = pulse_1hz & (sec >= 6'd59);
    assign min_carry = sec_carry & (min >= 6'd59);


    //---------------------------------------------------------
    // Sequential
    //---------------------------------------------------------
    // SEC register
    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin
            sec <= 6'd0;
        end
        else if (clk_en_10khz) begin
            if (load_en) begin
                sec <= load_data[5:0];
            end
            else if (pulse_1hz) begin
                // Free run count
                if (sec >= 6'd59)
                    sec <= 6'd0;
                else
                    sec <= sec + 1'b1;
            end
        end
    end


    // MIN register
    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin
            min <= 6'd0;
        end
        else if (clk_en_10khz) begin
            if (load_en) begin
                min <= load_data[11:6];
            end
            else if (sec_carry) begin
                if (min >= 6'd59)
                    min <= 6'd0;
                else
                    min <= min + 1'b1;
            end
        end
    end


    // HOUR register
    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin
            hour <= 5'd0;
        end
        else if (clk_en_10khz) begin
            if (load_en) begin
                hour <= load_data[16:12];
            end
            else if (min_carry) begin
                if (hour >= 5'd23)
                    hour <= 5'd0;
                else
                    hour <= hour + 1'b1;
            end
        end
    end


    // Output
    assign main_hour = hour;
    assign main_min  = min;
    assign main_sec  = sec;

endmodule