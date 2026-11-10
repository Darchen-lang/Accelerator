`timescale 1ns / 1ps

module irnet_residual_block #(
    parameter int INPUT_BITS   = 144,
    parameter int OUT_CHANNELS = 16,
    parameter int THRESHOLD_BITS = 8
) (
    input  logic [INPUT_BITS-1:0] data_in,
    // Flattened ports for synthesis compatibility
    input  logic [(INPUT_BITS * OUT_CHANNELS)-1:0] weight_conv1_flat,
    input  logic [(THRESHOLD_BITS * OUT_CHANNELS)-1:0] threshold_conv1_flat,
    input  logic [(INPUT_BITS * OUT_CHANNELS)-1:0] weight_conv2_flat,
    input  logic [(THRESHOLD_BITS * OUT_CHANNELS)-1:0] threshold_conv2_flat,
    input  logic [OUT_CHANNELS-1:0] shortcut_in,
    output logic [OUT_CHANNELS-1:0] data_out
);

    logic [INPUT_BITS-1:0] weight_conv1 [0:OUT_CHANNELS-1];
    logic [THRESHOLD_BITS-1:0] threshold_conv1 [0:OUT_CHANNELS-1];
    logic [INPUT_BITS-1:0] weight_conv2 [0:OUT_CHANNELS-1];
    logic [THRESHOLD_BITS-1:0] threshold_conv2 [0:OUT_CHANNELS-1];
    integer i;

    always_comb begin
        for (i = 0; i < OUT_CHANNELS; i++) begin
            weight_conv1[i]    = weight_conv1_flat[i * INPUT_BITS +: INPUT_BITS];
            threshold_conv1[i] = threshold_conv1_flat[i * THRESHOLD_BITS +: THRESHOLD_BITS];
            weight_conv2[i]    = weight_conv2_flat[i * INPUT_BITS +: INPUT_BITS];
            threshold_conv2[i] = threshold_conv2_flat[i * THRESHOLD_BITS +: THRESHOLD_BITS];
        end
    end

    logic [OUT_CHANNELS-1:0] conv1_out;
    logic [OUT_CHANNELS-1:0] conv2_out;

    irnet_conv1 #(
        .INPUT_BITS(INPUT_BITS),
        .OUT_CHANNELS(OUT_CHANNELS),
        .THRESHOLD_BITS(THRESHOLD_BITS)
    ) u_conv1 (
        .data_in(data_in),
        .weight_flat(weight_conv1_flat),
        .threshold_flat(threshold_conv1_flat),
        .data_out(conv1_out)
    );

    irnet_conv1 #(
        .INPUT_BITS(INPUT_BITS),
        .OUT_CHANNELS(OUT_CHANNELS),
        .THRESHOLD_BITS(THRESHOLD_BITS)
    ) u_conv2 (
        .data_in(data_in),
        .weight_flat(weight_conv2_flat),
        .threshold_flat(threshold_conv2_flat),
        .data_out(conv2_out)
    );

    always_comb begin
        for (i = 0; i < OUT_CHANNELS; i++) begin
            data_out[i] = (conv1_out[i] | shortcut_in[i]) & conv2_out[i];
        end
    end

endmodule