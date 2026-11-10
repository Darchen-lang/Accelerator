`timescale 1ns / 1ps

module layer1_conv1 (
    input  logic         clk,
    input  logic         rst_n,
    input  logic [143:0] data_in,
    output logic [15:0]  data_out
);

    localparam int INPUT_WIDTH     = 144;
    localparam int OUTPUT_WIDTH    = 16;
    localparam int POPCOUNT_WIDTH  = 8;
    localparam int THRESHOLD_WIDTH = 16;

    logic [INPUT_WIDTH-1:0]     weight_rom    [0:OUTPUT_WIDTH-1];
    logic [THRESHOLD_WIDTH-1:0] threshold_lut [0:OUTPUT_WIDTH-1];

    generate
        for (genvar i = 0; i < OUTPUT_WIDTH; i++) begin : gen_pe
            logic [INPUT_WIDTH-1:0]    xnor_result;
            logic [POPCOUNT_WIDTH-1:0] popcount;
            integer k;

            always_comb begin
                xnor_result = ~(data_in ^ weight_rom[i]);
                popcount = '0;
                for (k = 0; k < INPUT_WIDTH; k++) begin
                    popcount = popcount + xnor_result[k];
                end

                if (popcount >= threshold_lut[i])
                    data_out[i] = 1'b1;
                else
                    data_out[i] = 1'b0;
            end
        end
    endgenerate

endmodule