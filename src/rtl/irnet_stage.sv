`timescale 1ns / 1ps

module irnet_stage #(
    parameter int INPUT_BITS     = 144,
    parameter int CHANNELS       = 16,
    parameter int THRESHOLD_BITS = 8,
    parameter int BLOCKS         = 3
) (
    input  logic [INPUT_BITS-1:0] data_in,
    // Flattened multi-dimensional arrays for synthesis compatibility
    input  logic [(BLOCKS * CHANNELS * INPUT_BITS)-1:0] weight_block_flat,
    input  logic [(BLOCKS * CHANNELS * THRESHOLD_BITS)-1:0] threshold_block_flat,
    input  logic [CHANNELS-1:0] shortcut_in,
    output logic [CHANNELS-1:0] data_out
);

    localparam int BLOCK_WEIGHT_BITS = CHANNELS * INPUT_BITS;
    localparam int BLOCK_THRESH_BITS = CHANNELS * THRESHOLD_BITS;

    logic [BLOCK_WEIGHT_BITS-1:0] weight_block_0_flat;
    logic [BLOCK_THRESH_BITS-1:0] threshold_block_0_flat;
    logic [BLOCK_WEIGHT_BITS-1:0] weight_block_1_flat;
    logic [BLOCK_THRESH_BITS-1:0] threshold_block_1_flat;
    logic [BLOCK_WEIGHT_BITS-1:0] weight_block_2_flat;
    logic [BLOCK_THRESH_BITS-1:0] threshold_block_2_flat;

    // Continuous assignments avoid iverilog constant-select warnings in always_comb
    assign weight_block_0_flat    = weight_block_flat[0 * BLOCK_WEIGHT_BITS +: BLOCK_WEIGHT_BITS];
    assign threshold_block_0_flat = threshold_block_flat[0 * BLOCK_THRESH_BITS +: BLOCK_THRESH_BITS];
    
    assign weight_block_1_flat    = weight_block_flat[1 * BLOCK_WEIGHT_BITS +: BLOCK_WEIGHT_BITS];
    assign threshold_block_1_flat = threshold_block_flat[1 * BLOCK_THRESH_BITS +: BLOCK_THRESH_BITS];
    
    assign weight_block_2_flat    = weight_block_flat[2 * BLOCK_WEIGHT_BITS +: BLOCK_WEIGHT_BITS];
    assign threshold_block_2_flat = threshold_block_flat[2 * BLOCK_THRESH_BITS +: BLOCK_THRESH_BITS];

    logic [CHANNELS-1:0] out_0;
    logic [CHANNELS-1:0] out_1;
    logic [CHANNELS-1:0] out_2;

    irnet_residual_block #(
        .INPUT_BITS(INPUT_BITS),
        .OUT_CHANNELS(CHANNELS),
        .THRESHOLD_BITS(THRESHOLD_BITS)
    ) u_block0 (
        .data_in(data_in),
        .weight_conv1_flat(weight_block_0_flat),
        .threshold_conv1_flat(threshold_block_0_flat),
        .weight_conv2_flat(weight_block_0_flat),
        .threshold_conv2_flat(threshold_block_0_flat),
        .shortcut_in(shortcut_in),
        .data_out(out_0)
    );

    irnet_residual_block #(
        .INPUT_BITS(INPUT_BITS),
        .OUT_CHANNELS(CHANNELS),
        .THRESHOLD_BITS(THRESHOLD_BITS)
    ) u_block1 (
        .data_in({{(INPUT_BITS-CHANNELS){1'b0}}, out_0}),
        .weight_conv1_flat(weight_block_1_flat),
        .threshold_conv1_flat(threshold_block_1_flat),
        .weight_conv2_flat(weight_block_1_flat),
        .threshold_conv2_flat(threshold_block_1_flat),
        .shortcut_in(out_0),
        .data_out(out_1)
    );

    irnet_residual_block #(
        .INPUT_BITS(INPUT_BITS),
        .OUT_CHANNELS(CHANNELS),
        .THRESHOLD_BITS(THRESHOLD_BITS)
    ) u_block2 (
        .data_in({{(INPUT_BITS-CHANNELS){1'b0}}, out_1}),
        .weight_conv1_flat(weight_block_2_flat),
        .threshold_conv1_flat(threshold_block_2_flat),
        .weight_conv2_flat(weight_block_2_flat),
        .threshold_conv2_flat(threshold_block_2_flat),
        .shortcut_in(out_1),
        .data_out(out_2)
    );

    assign data_out = out_2;

endmodule