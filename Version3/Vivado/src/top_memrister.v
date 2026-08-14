`timescale 1ns / 1ps

module top_memristor (
    input  wire clk,
    input  wire rst
);

 (* keep = "true", mark_debug = "true" *) wire signed [15:0] V_sine;
(* keep = "true", mark_debug = "true" *) wire signed [15:0] I_output;
(* keep = "true", mark_debug = "true" *) wire        [7:0]  R_value;
(* keep = "true", mark_debug = "true" *) wire signed [7:0]  state_x;
(* keep = "true", mark_debug = "true" *) wire        [1:0]  dir;

ila_0 your_ila (
    .clk(clk),
    .probe0(state_x),
    .probe1(dir),
    .probe2(R_value),
    .probe3(I_output),
    .probe4(V_sine)
);

    // Instances
    phase_accumulator #(.CLK_HZ(12_000_000), .SINE_HZ(1000)) wave_gen_inst (
        .clk(clk), .rst(rst), .sine_out(V_sine)
    );

    memristor_core #(.Ron(8'd10), .Roff(8'd90), .STATE_GAIN(20), .window_floor(8'd8)) memristor_inst (
        .clk(clk), .rst(rst), .V_in(V_sine),
        .I_out(I_output), .Rmem(R_value), .state_x(state_x), .dir(dir)
    );


endmodule 
