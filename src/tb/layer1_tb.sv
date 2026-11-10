`timescale 1ns / 1ps

module layer1_tb;

    // 1. Declare virtual wires to plug into our chip
    logic clk;
    logic rst_n;
    logic [143:0] data_in;
    logic [15:0] data_out;

    // 2. Drop down a copy of our chip (Device Under Test)
    layer1_conv1 dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    // 3. Start the heartbeat: flip the clock signal every 5 nanoseconds
    always #5 clk = ~clk;

    // Arrays to hold Person 2's stimulus and golden reference files
    logic [143:0] test_input [0:0];
    logic [15:0] expected_mem [0:0];
    logic [143:0] weight_mem [0:15];
    logic [15:0] threshold_mem [0:15];

    // The threshold values are stored as integer registers and compared to the
    // XNOR-popcount result for each output channel.

    // 4. The main simulation sequence
    initial begin
        // Setup waveform recording so we can visually debug later
        $dumpfile("wave.vcd");
        $dumpvars(0, layer1_tb);

        // Load Person 2's hex files into the testbench from the data directory.
        $readmemh("data/input_stimulus.hex", test_input);
        $readmemh("data/expected_output.hex", expected_mem);
        $readmemh("data/weights.hex", weight_mem);
        $readmemh("data/thresholds.hex", threshold_mem);

        for (int i = 0; i < 16; i++) begin
            dut.weight_rom[i] = weight_mem[i];
            dut.threshold_lut[i] = threshold_mem[i];
        end

        // Initialize all pins to zero (holding reset down)
        clk = 0;
        rst_n = 0; 
        data_in = 0;

        // Wait 10 nanoseconds, then release the reset pin
        #10;
        rst_n = 1;

        // Wait another 10ns, then blast the 144-bit image data into the chip.
        #10;
        data_in = test_input[0];

        // Wait 10ns to let the electrical signals propagate through the XNOR gates
        #10;

        // 5. Automatic Verification
        if (data_out === expected_mem[0]) begin
            $display("SUCCESS: Hardware logic perfectly matches the math model! Output: %h", data_out);
        end else begin
            $display("ERROR: Mismatch. Expected %h, got %h", expected_mem[0], data_out);
        end

        // Run for 20 more nanoseconds, then pull the plug on the simulation
        #20;
        $finish;
    end

endmodule