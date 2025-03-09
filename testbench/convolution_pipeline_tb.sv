module convolution_pipeline_tb;

    localparam int C_SIGNAL_WIDTH = 12;        // 12-bit pixels
    localparam int C_KERNEL_DIMENSION = 3;       // 3x3 kernel

    logic clk;
    logic rst;
    logic en;

    //Equivalent to the custom "window" type in user_pkg.vhd
    logic[C_SIGNAL_WIDTH-1:0] window_input [0:C_KERNEL_DIMENSION-1][0:C_KERNEL_DIMENSION-1];
    //Equivalent to the custom "kernel" type in user_pkg.vhd
    logic signed [C_SIGNAL_WIDTH-1:0] filter [0:C_KERNEL_DIMENSION-1][0:C_KERNEL_DIMENSION-1];

    logic [C_SIGNAL_WIDTH-1:0] dut_out;
    //Declare the DUT, signals will be driven in initial block
    convolution_pipeline dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .window_input(window_input),
        .filter(filter),
        .output_pixel(dut_out)
    );

    //Clock generation block
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //Reset block, initializes everything to 0s
    initial begin
        rst = 1;
        en = 0;
        #20;
        rst = 0;
    end

    //Actual test stimulus to DUT
    initial begin
        integer i,j;
        @(negedge rst); //Wait until reset is complete
        #10;

        //Initialize test window data
        for (i = 0; i < C_KERNEL_DIMENSION; i++) begin
            for (j = 0; j < C_KERNEL_DIMENSION; j++) begin
              window_input[i][j] <= 12;
            end
          end

        //Case 1: test data convolved with identity kernel
        for(i = 0; i < C_KERNEL_DIMENSION; i++) begin
            for(j = 0; j < C_KERNEL_DIMENSION; j++) begin
                if(i==1 && j==1)
                    filter[i][j] <= 1;
                else
                    filter[i][j] <= 0;
            end
        end
        en = 1;
        repeat(7) @(posedge clk);
        if(dut_out != 12'd12)
            $error("Test case 1 FAILED: Expected 12, got %0d", dut_out);
        else
            $display("Test case 1 PASSED: dut_out = %0d",dut_out);
    end
    
    
endmodule