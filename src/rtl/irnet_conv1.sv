`timescale 1ns / 1ps

module irnet_conv1 #(
    parameter int INPUT_BITS  = 144,
    parameter int OUT_CHANNELS = 16,
    parameter int THRESHOLD_BITS = 8
) (
    input  logic [INPUT_BITS-1:0] data_in,
    input  logic [(INPUT_BITS * OUT_CHANNELS)-1:0] weight_flat,
    input  logic [(THRESHOLD_BITS * OUT_CHANNELS)-1:0] threshold_flat,
    output logic [OUT_CHANNELS-1:0] data_out
);

    logic [INPUT_BITS-1:0] weight_rom [0:OUT_CHANNELS-1];
    logic [THRESHOLD_BITS-1:0] threshold_lut [0:OUT_CHANNELS-1];
    integer i;

    always_comb begin
        for (i = 0; i < OUT_CHANNELS; i++) begin
            weight_rom[i]    = weight_flat[i * INPUT_BITS +: INPUT_BITS];
            threshold_lut[i] = threshold_flat[i * THRESHOLD_BITS +: THRESHOLD_BITS];
        end
    end

    generate
        for (genvar g = 0; g < OUT_CHANNELS; g++) begin : g_pe
            logic [INPUT_BITS-1:0] xnor_result;
            logic [THRESHOLD_BITS-1:0] popcount;
            integer k;

            always_comb begin
                xnor_result = ~(data_in ^ weight_rom[g]);
                popcount = '0;
                for (k = 0; k < INPUT_BITS; k++) begin
                    popcount = popcount + xnor_result[k];
                end
                data_out[g] = (popcount >= threshold_lut[g]);
            end
        end
    endgenerate

endmodule