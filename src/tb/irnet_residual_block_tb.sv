`timescale 1ns / 1ps

module irnet_residual_block_tb;

    localparam int INPUT_BITS     = 144;
    localparam int OUT_CHANNELS   = 16;
    localparam int THRESHOLD_BITS = 8;

    logic [INPUT_BITS-1:0] data_in;
    logic [INPUT_BITS-1:0] weight_conv1 [0:OUT_CHANNELS-1];
    logic [THRESHOLD_BITS-1:0] threshold_conv1 [0:OUT_CHANNELS-1];
    logic [INPUT_BITS-1:0] weight_conv2 [0:OUT_CHANNELS-1];
    logic [THRESHOLD_BITS-1:0] threshold_conv2 [0:OUT_CHANNELS-1];
    logic [OUT_CHANNELS-1:0] shortcut_in;
    logic [OUT_CHANNELS-1:0] data_out;

    // Flattened buses to connect to the DUT
    logic [(INPUT_BITS * OUT_CHANNELS)-1:0] weight_conv1_flat;
    logic [(THRESHOLD_BITS * OUT_CHANNELS)-1:0] threshold_conv1_flat;
    logic [(INPUT_BITS * OUT_CHANNELS)-1:0] weight_conv2_flat;
    logic [(THRESHOLD_BITS * OUT_CHANNELS)-1:0] threshold_conv2_flat;

    // Pack the 1D arrays into flat vectors
    always_comb begin
        for (int i = 0; i < OUT_CHANNELS; i++) begin
            weight_conv1_flat[i * INPUT_BITS +: INPUT_BITS]          = weight_conv1[i];
            threshold_conv1_flat[i * THRESHOLD_BITS +: THRESHOLD_BITS] = threshold_conv1[i];
            weight_conv2_flat[i * INPUT_BITS +: INPUT_BITS]          = weight_conv2[i];
            threshold_conv2_flat[i * THRESHOLD_BITS +: THRESHOLD_BITS] = threshold_conv2[i];
        end
    end

    irnet_residual_block #(
        .INPUT_BITS(INPUT_BITS),
        .OUT_CHANNELS(OUT_CHANNELS),
        .THRESHOLD_BITS(THRESHOLD_BITS)
    ) dut (
        .data_in(data_in),
        .weight_conv1_flat(weight_conv1_flat),
        .threshold_conv1_flat(threshold_conv1_flat),
        .weight_conv2_flat(weight_conv2_flat),
        .threshold_conv2_flat(threshold_conv2_flat),
        .shortcut_in(shortcut_in),
        .data_out(data_out)
    );

    initial begin
        integer c;
        $dumpfile("build/wave.vcd");
        $dumpvars(0, irnet_residual_block_tb);

        for (c = 0; c < OUT_CHANNELS; c++) begin
            weight_conv1[c]    = '1;
            threshold_conv1[c] = 8'd100;
            weight_conv2[c]    = '1;
            threshold_conv2[c] = 8'd100;
        end

        // Test 1: Active conv1, conv2, and shortcut -> Output all 1s
        data_in     = '1;
        shortcut_in = 16'hFFFF;
        #10;
        if (data_out == 16'hFFFF) begin
            $display("PASS: Residual block active path verified");
        end else begin
            $display("FAIL: expected ffff, got %h", data_out);
            $fatal;
        end

        // Test 2: Zero stimulus and zero shortcut -> Output all 0s
        data_in     = '0;
        shortcut_in = 16'h0000;
        #10;
        if (data_out == 16'h0000) begin
            $display("PASS: Residual block zero suppression verified");
        end else begin
            $display("FAIL: expected 0000, got %h", data_out);
            $fatal;
        end

        $finish;
    end

endmodule