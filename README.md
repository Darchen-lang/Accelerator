# IR-Net Binary Neural Network Hardware Project

This workspace implements the first binary IR-Net-style layer and related RTL verification for a ResNet-20 1W1A design on CIFAR-10.

## Directory layout

- `src/rtl/` — synthesizable RTL modules
- `src/tb/` — testbenches for simulation and verification
- `data/` — exported weights, thresholds, and stimulus vectors used by the RTL testbench
- `build/` — compiled simulation outputs and waveform files

## Core RTL files

- `src/rtl/layer1_conv1.sv` — verified XNOR + popcount + threshold comparator for the first IR-Net layer
- `src/rtl/irnet_conv1.sv` — simplified binary PE block
- `src/rtl/irnet_residual_block.sv` — residual datapath block
- `src/rtl/irnet_stage.sv` — stage-level abstraction for a binary residual stack

## Verification files

- `src/tb/layer1_tb.sv` — main verification testbench for the first layer
- `src/tb/irnet_conv1_tb.sv` — standalone PE verification
- `src/tb/irnet_residual_block_tb.sv` — residual-block verification
- `src/tb/irnet_stage_tb.sv` — stage-level verification

## Data files

- `data/weights.hex` — binary weight ROM contents
- `data/thresholds.hex` — per-channel thresholds from BN conversion
- `data/input_stimulus.hex` — test stimulus input patch
- `data/expected_output.hex` — golden output pattern for layer1 verification

## Simulation command

```bash
cd /home/samaksh/Desktop/vlsi
iverilog -g2012 -Wall -DSIMULATION -s layer1_tb -o build/out.vvp src/rtl/layer1_conv1.sv src/tb/layer1_tb.sv
vvp build/out.vvp
```

## Notes

- This project follows the IR-Net paper idea: binary weights and activations, XNOR-based convolution, popcount-based accumulation, and threshold-based activation.
- The implementation is intended as a research/prototype hardware translation, not a full production ASIC implementation.
