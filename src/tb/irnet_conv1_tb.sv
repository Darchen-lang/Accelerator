`timescale 1ns / 1ps

module irnet_conv1_tb;

    localparam int INPUT_BITS     = 144;
    localparam int OUT_CHANNELS   = 16;
    localparam int THRESHOLD_BITS = 8;

    logic [INPUT_BITS-1:0] data_in;
    logic [INPUT_BITS-1:0] weight_rom [0:OUT_CHANNELS-1];
    logic [THRESHOLD_BITS-1:0] threshold_lut [0:OUT_CHANNELS-1];
    
    // Flattened buses to connect to the DUT
    logic [(INPUT_BITS * OUT_CHANNELS)-1:0] weight_flat;
    logic [(THRESHOLD_BITS * OUT_CHANNELS)-1:0] threshold_flat;
    logic [OUT_CHANNELS-1:0] data_out;

    // Pack the 1D arrays into flat vectors
    always_comb begin
        for (int i = 0; i < OUT_CHANNELS; i++) begin
            weight_flat[i * INPUT_BITS +: INPUT_BITS]          = weight_rom[i];
            threshold_flat[i * THRESHOLD_BITS +: THRESHOLD_BITS] = threshold_lut[i];
        end
    end

    irnet_conv1 #(
        .INPUT_BITS(INPUT_BITS),
        .OUT_CHANNELS(OUT_CHANNELS),
        .THRESHOLD_BITS(THRESHOLD_BITS)
    ) dut (
        .data_in(data_in),
        .weight_flat(weight_flat),
        .threshold_flat(threshold_flat),
        .data_out(data_out)
    );

    initial begin
        integer c;
        $dumpfile("build/wave.vcd");
        $dumpvars(0, irnet_conv1_tb);

        // Initialize all weights to 1 and threshold to 100
        for (c = 0; c < OUT_CHANNELS; c++) begin
            weight_rom[c]    = '1;
            threshold_lut[c] = 8'd100;
        end

        // Test 1: Full match (popcount = 144 >= 100 -> all 1s)
        data_in = '1;
        #10;
        if (data_out == 16'hFFFF) begin
            $display("PASS: irnet_conv1 all-ones match test passed");
        end else begin
            $display("FAIL: irnet_conv1 expected ffff, got %h", data_out);
            $fatal;
        end

        // Test 2: Zero match (popcount = 0 < 100 -> all 0s)
        data_in = '0;
        #10;
        if (data_out == 16'h0000) begin
            $display("PASS: irnet_conv1 zero-mismatch suppression passed");
        end else begin
            $display("FAIL: irnet_conv1 expected 0000, got %h", data_out);
            $fatal;
        end

        $finish;
    end

endmodule