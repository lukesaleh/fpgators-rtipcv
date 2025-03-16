`timescale 1 ns / 1 ps

module convolution_pipeline_tb2 #(
    parameter int C_SIGNAL_WIDTH     = 12,
    parameter int C_KERNEL_DIMENSION = 3,
    parameter int C_KERNEL_WIDTH     = 13
);

    //Latency for a pipeline propagation
    localparam int LATENCY = 6;

    //DUT signals
    logic clk = 1'b0;
    logic rst;
    logic en;

    // 3×3 window of 12-bit signals
    logic [C_SIGNAL_WIDTH-1:0] window_input [C_KERNEL_DIMENSION-1:0][C_KERNEL_DIMENSION-1:0];

    // 3×3 kernel of signed 13-bit values
    logic signed [C_KERNEL_WIDTH-1:0] filter [C_KERNEL_DIMENSION-1:0][C_KERNEL_DIMENSION-1:0];

    // DUT output
    logic [C_SIGNAL_WIDTH-1:0] dut_out;

    convolution_pipeline dut (
        .clk          (clk),
        .rst          (rst),
        .en           (en),
        .window_input (window_input),
        .filter       (filter),
        .output_pixel (dut_out)
    );

    initial begin : generate_clock
        forever #5 clk = ~clk;
    end

    //Reference function to compare values
    function automatic logic [C_SIGNAL_WIDTH-1:0]
        model_conv(
            input logic [C_SIGNAL_WIDTH-1:0]                w [C_KERNEL_DIMENSION-1:0][C_KERNEL_DIMENSION-1:0],
            input logic signed [C_KERNEL_WIDTH-1:0]         f [C_KERNEL_DIMENSION-1:0][C_KERNEL_DIMENSION-1:0]
        );
        // Since 12-bit (unsigned) × 13-bit (signed) = up to 26 bits,
        // and we sum 9 such products so use a signed 35-bit accumulator.
        logic signed [34:0] sum = 0;
        for (int i = 0; i < C_KERNEL_DIMENSION; i++) begin
            for (int j = 0; j < C_KERNEL_DIMENSION; j++) begin
                // Sign-extend the 12-bit pixel
                logic signed [34:0] pixel  = $signed(w[i][j]);
                // Sign-extend the 13-bit filter
                logic signed [34:0] coeff  = f[i][j];
                sum += (pixel * coeff);
            end
        end

        // Now saturate to 12 bits [0..4095]
        if (sum < 0) sum = 0;
        else if (sum > 4095) sum = 4095;

        return sum[11:0];
    endfunction

    //Block to drive stimulus of DUT
    initial begin : main_test
        $timeformat(-9, 0, " ns", 0);
        
        // 1) Apply reset
        rst <= 1;
        en  <= 0;
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst <= 0;
        @(posedge clk);

        // CASE 1: 3×3 window of 12’s, Identity kernel
        for (int i = 0; i < C_KERNEL_DIMENSION; i++) begin
            for (int j = 0; j < C_KERNEL_DIMENSION; j++) begin
                window_input[i][j] <= 12; 
                if ((i == 1) && (j == 1))  filter[i][j] <= 1;  // identity center
                else                       filter[i][j] <= 0;
            end
        end
        en <= 1;
        @(posedge clk);

        // CASE 2: 3×3 window of 10s, diagonal kernel = -1 => expect clamp to 0
        for (int i = 0; i < C_KERNEL_DIMENSION; i++) begin
            for (int j = 0; j < C_KERNEL_DIMENSION; j++) begin
                window_input[i][j] <= 10;
                filter[i][j] <= (i == j) ? -1 : 0;
            end
        end
        @(posedge clk);

        // CASE 3: 3×3 window of 4095, identity diag => expect clamp to 4095
        for (int i = 0; i < C_KERNEL_DIMENSION; i++) begin
            for (int j = 0; j < C_KERNEL_DIMENSION; j++) begin
                window_input[i][j] <= 12'd4095;
                filter[i][j]       <= (i == j) ? 1 : 0;
            end
        end

        // Let the pipeline run
        @(posedge clk);
        
        // Wait some extra cycles for pipeline to flush 
        // (since we’re also verifying with SVA, we can still do a final check)
        repeat (8) @(posedge clk);

        $display("Manual stimulus completed. Now checking results with SVA and final checks...");
        disable generate_clock;  // stop the clock
        $finish;
    end

    //Check assertions are valid

    property p_check_output;
        @(posedge clk) disable iff (rst)
        // After 'en' is true for LATENCY cycles, compare output
        en [-> LATENCY] |-> ( dut_out == model_conv(
                                $past(window_input, LATENCY, en),
                                $past(filter,       LATENCY, en)
                             )
                           );
    endproperty
    assert property (p_check_output)
        else $error("Convolution mismatch with reference model after %0d cycles", LATENCY);


    //Reset assertion
    property p_reset_clears_output;
        @(posedge clk) $fell(rst) |-> (dut_out == '0) throughout en [-> LATENCY];
    endproperty
    assert property (p_reset_clears_output)
        else $error("Pipeline output was not 0 after reset deasserted for %0d cycles", LATENCY);

    //Check stalled output
    property p_stall;
        @(posedge clk) disable iff (rst) !en |=> $stable(dut_out);
    endproperty
    assert property (p_stall)
        else $error("Pipeline output changed while en=0 (stall)");


endmodule
