`timescale 1ns / 1ps

module irnet_stage_tb;

    localparam int INPUT_BITS     = 144;
    localparam int CHANNELS       = 16;
    localparam int THRESHOLD_BITS = 8;
    localparam int BLOCKS         = 3;

    logic [INPUT_BITS-1:0] data_in;
    logic [INPUT_BITS-1:0] weight_block [0:BLOCKS-1][0:CHANNELS-1];
    logic [THRESHOLD_BITS-1:0] threshold_block [0:BLOCKS-1][0:CHANNELS-1];
    logic [CHANNELS-1:0] shortcut_in;
    logic [CHANNELS-1:0] data_out;

    // Flattened buses to connect to the DUT
    logic [(BLOCKS * CHANNELS * INPUT_BITS)-1:0] weight_block_flat;
    logic [(BLOCKS * CHANNELS * THRESHOLD_BITS)-1:0] threshold_block_flat;

    // Pack the 2D arrays into flat vectors
    always_comb begin
        for (int b = 0; b < BLOCKS; b++) begin
            for (int c = 0; c < CHANNELS; c++) begin
                weight_block_flat[(b * CHANNELS + c) * INPUT_BITS +: INPUT_BITS]          = weight_block[b][c];
                threshold_block_flat[(b * CHANNELS + c) * THRESHOLD_BITS +: THRESHOLD_BITS] = threshold_block[b][c];
            end
        end
    end

    irnet_stage dut (
        .data_in(data_in),
        .weight_block_flat(weight_block_flat),
        .threshold_block_flat(threshold_block_flat),
        .shortcut_in(shortcut_in),
        .data_out(data_out)
    );

    initial begin
        integer b, c;
        $dumpfile("build/wave.vcd");
        $dumpvars(0, irnet_stage_tb);

        for (b = 0; b < BLOCKS; b++) begin
            for (c = 0; c < CHANNELS; c++) begin
                weight_block[b][c] = '1;
                if (b == 0)
                    threshold_block[b][c] = 8'd100;
                else
                    threshold_block[b][c] = 8'd10;
            end
        end

        data_in = '1;
        shortcut_in = 16'hFFFF;
        #10;

        if (data_out == 16'hFFFF) begin
            $display("PASS: 3-block IR-Net stage preserves the binary residual path");
        end else begin
            $display("FAIL: expected %h, got %h", 16'hFFFF, data_out);
            $fatal;
        end

        data_in = '0;
        shortcut_in = 16'h0000;
        #10;

        if (data_out == 16'h0000) begin
            $display("PASS: zero stimulus suppresses stage output");
        end else begin
            $display("FAIL: expected %h, got %h", 16'h0000, data_out);
            $fatal;
        end

        $finish;
    end

endmodule