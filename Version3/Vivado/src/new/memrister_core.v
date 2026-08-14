/*
`timescale 1ns / 1ps

module memristor_core #(
    parameter [7:0] Ron  = 8'd10,
    parameter [7:0] Roff = 8'd90
)(
    input  wire                     clk,
    input  wire                     rst,
    input  wire signed [15:0]       V_in,    // Fed directly from your sine output
    output reg  signed [15:0]       I_out,   // Calculated dynamically via Ohm's law
    output reg  [7:0]               Rmem,    // Dynamic resistance state
    output reg  signed [7:0]        state_x, // Internal tracking state variable
    output reg  [1:0]               dir      // Debug monitoring direction line
);

    // Temporary calculations for scaling state_x down linearly
    wire [15:0] norm_x;
    wire [15:0] r_diff;
    wire [31:0] Temp_Product;

    // Fixed: Using 16'sd128 prevents 8-bit signed compiler overflow
    assign norm_x = state_x + 16'sd128;
    assign r_diff = Roff - Ron;
    assign Temp_Product = norm_x * r_diff;

    // Hysteresis boundary-state evaluation loop
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_x <= 8'sd0;
            dir     <= 2'b00;
        end else begin
            if (V_in > 16'sd0) begin
                // Positive quadrant behavior 
                if (state_x >= 8'sd0 && state_x < 8'sd127) begin
                    dir     <= 2'b00;
                    state_x <= state_x + 8'sd1;
                end else begin
                    dir <= 2'b01;
                    if (state_x != -8'sd1) begin
                        state_x <= state_x - 8'sd1;
                    end
                end
            end else if (V_in < 16'sd0) begin
                // Negative quadrant behavior
                if (state_x > -8'sd128 && state_x <= 8'sd0) begin
                    dir     <= 2'b10;
                    state_x <= state_x - 8'sd1;
                end else begin
                    dir <= 2'b11;
                    if (state_x != 8'sd1) begin
                        state_x <= state_x + 8'sd1;
                    end
                end
            end
        end
    end

    // Dynamic Resistive Calculation Loop
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            Rmem <= Roff; 
        end else begin
            if (state_x == 8'sd126 || state_x == -8'sd127) begin
                Rmem <= Ron;
            end else if (state_x == 8'sd0 || state_x == -8'sd1) begin
                Rmem <= Roff;
            end else begin
                // Shift bits by 8 to transform our 16-bit intermediate product back down to an 8-bit scale
                Rmem <= Roff - (Temp_Product[15:8]);
            end
        end
    end

    // Ohm's law calculation: I = V / R
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            I_out <= 16'sd0;
        end else begin
            if (Rmem != 8'd0) begin
                I_out <= V_in / $signed({1'b0, Rmem});
            end else begin
                I_out <= 16'sd0; // Catch division by zero safely
            end
        end
    end

endmodule
*/
`timescale 1ns / 1ps

// Drop-in replacement for your existing memristor_core module.
// Same ports, same ILA widths.  The difference is that state_x is now a
// slow fixed-point integrator of V_in instead of jumping by 1 every FPGA clock.

`timescale 1ns / 1ps

module memristor_core #(
    parameter [7:0] Ron  = 8'd10,
    parameter [7:0] Roff = 8'd90,

    // Internal state uses Q8.FRAC_BITS fixed point.
    // This acts as our "gear reduction" to slow down the 12 MHz FPGA clock
    // so the state integrates smoothly over the 1 kHz sine wave period.
    parameter integer FRAC_BITS   = 16,
    parameter integer STATE_GAIN  = 8,
    parameter integer use_joglekar_window = 1,
    parameter integer window_shift = 8,
    parameter [7:0] window_floor = 8'd8,
    parameter window_file = "/home/think/Vivado_Project/MemristerVersion3/MemristerVersion3.srcs/sources_1/new/joglekar_window_256x8.mem",

    // Reset state. 0 means middle-ish state_x, not fully ON or OFF.
    parameter signed [7:0] X_INIT = 8'sd0
)(
    input  wire                     clk,
    input  wire                     rst,
    input  wire signed [15:0]       V_in,
    output reg  signed [15:0]       I_out,
    output reg  [7:0]               Rmem,
    output reg  signed [7:0]        state_x,
    output reg  [1:0]               dir
);

    // Physical boundaries for the memristor state
    localparam signed [31:0] X_MIN = (-32'sd128) <<< FRAC_BITS;
    localparam signed [31:0] X_MAX = ( 32'sd127) <<< FRAC_BITS;
    localparam signed [15:0] STATE_GAIN_S = STATE_GAIN;

    // Registers for fixed-point math and state tracking
    reg signed [31:0] x_q;
    reg signed [31:0] next_x;
    reg signed [31:0] x_int_next;
    reg        [8:0]  norm_next;
    reg        [15:0] r_calc;

    // Wires for scaled calculations
    wire signed [31:0] v_in_32;
    wire signed [31:0] gain_32;
    wire signed [31:0] dx_base;
    wire signed [31:0] dx_q;
    wire signed [40:0] dx_windowed_full;
    wire signed [31:0] i_calc_scaled;
    wire signed [15:0] i_calc;
    wire signed [8:0]  Rmem_signed;
    wire        [7:0]  r_diff;
    wire        [8:0]  window_addr_wide;
    wire        [7:0]  window_addr;
    wire        [7:0]  window_value;
    wire        [7:0]  window_gain;

    // Joglekar window ROM. The address is the visible state_x shifted from
    // signed [-128,127] into unsigned [0,255].
    reg [7:0] joglekar_window [0:255];

    initial begin
        $readmemh(window_file, joglekar_window);
    end

    // Sign extension and scaling for smooth integration
    assign v_in_32  = {{16{V_in[15]}}, V_in};
    assign gain_32  = {{16{STATE_GAIN_S[15]}}, STATE_GAIN_S};
    
    // dx_base is the voltage-driven state movement before boundary shaping.
    assign dx_base  = v_in_32 * gain_32;

    assign window_addr_wide = $signed({state_x[7], state_x}) + 9'sd128;
    assign window_addr      = window_addr_wide[7:0];
    assign window_value     = joglekar_window[window_addr];
    assign window_gain      = use_joglekar_window ?
                              ((window_value == 8'd0) ? window_floor : window_value) :
                              8'hFF;

    // Joglekar shaping slows state movement near Ron/Roff boundaries.
    // A tiny floor prevents fixed-point endpoint lock after hard saturation.
    assign dx_windowed_full = dx_base * $signed({1'b0, window_gain});
    assign dx_q            = dx_windowed_full >>> window_shift;
    
    assign r_diff   = Roff - Ron;
    assign Rmem_signed = {1'b0, Rmem};
    
    // Fixed-point Ohm's law: I = (V / Rmem) with 8 extra fractional bits.
    // This keeps the ILA plot smooth without changing state_x or Rmem behavior.
    assign i_calc_scaled = (Rmem != 0) ? ((v_in_32 <<< 8) / Rmem_signed) : 32'sd0;
    assign i_calc = (i_calc_scaled > 32'sd32767)  ? 16'sh7FFF :
                    (i_calc_scaled < -32'sd32768) ? 16'sh8000 :
                    i_calc_scaled[15:0];

    // Combinational logic for the next state
    always @(*) begin
        // 1. Slow Integration: Add the voltage-dependent delta to the current state
        next_x = x_q + dx_q;

        // 2. Clamp physical state (fixes the bouncing issue)
        if (next_x > X_MAX)
            next_x = X_MAX;
        else if (next_x < X_MIN)
            next_x = X_MIN;

        // Convert Q8.FRAC state back to a visible signed 8-bit state for your ILA
        x_int_next = next_x >>> FRAC_BITS;
        if (x_int_next > 32'sd127)
            x_int_next = 32'sd127;
        else if (x_int_next < -32'sd128)
            x_int_next = -32'sd128;

        // Map signed state_x [-128,127] to normalized unsigned state [0,255] for resistance math
        norm_next = x_int_next + 32'sd128;

        // 3. Linear Resistance Mapping: norm=0 -> Roff, norm=255 -> Ron
        if (norm_next == 9'd0)
            r_calc = Roff;
        else if (norm_next >= 9'd255)
            r_calc = Ron;
        else
            r_calc = Roff - (((({7'd0, norm_next} * {8'd0, r_diff}) + 16'd127) / 16'd255));
    end

    // Sequential logic to update registers on the clock edge
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x_q     <= $signed({{24{X_INIT[7]}}, X_INIT}) <<< FRAC_BITS;
            state_x <= X_INIT;
            Rmem    <= Roff;
            I_out   <= 16'sd0;
            dir     <= 2'b00;
        end else begin
            x_q     <= next_x;
            state_x <= x_int_next[7:0];
            Rmem    <= r_calc[7:0];
            I_out   <= i_calc;

            // Cleaned up dir encoding for ILA debug (No more bouncing!):
            // 00 = no movement, 01 = increasing, 10 = decreasing, 11 = clamped at boundary
            if (((x_q >= X_MAX) && (dx_q > 0)) || ((x_q <= X_MIN) && (dx_q < 0)))
                dir <= 2'b11; 
            else if (dx_q > 0)
                dir <= 2'b01; 
            else if (dx_q < 0)
                dir <= 2'b10; 
            else
                dir <= 2'b00; 
        end
    end

endmodule
