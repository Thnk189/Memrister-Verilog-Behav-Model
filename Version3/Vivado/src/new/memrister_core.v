
`timescale 1ns / 1ps

module memristor_core #(
    // Resistance limits used by the state-to-resistance mapping. 
    // This will be eventually changed in version four where you can work backwards with real Voltage and Current Values to get what Ron would better fit as a 8 bit decimal value (could be greater or lower, same for Roff)
    parameter [7:0] Ron  = 8'd10,
    parameter [7:0] Roff = 8'd90,

// FRAC_BITS controls how quickly state_x changes while the memrister math still runs at 12Mhz
// Small voltage-driven updates accumulate over multiple clock cycles before state_x changes by one visible count.
    parameter integer FRAC_BITS   = 16,

    
     // Scales the voltage-driven state change. This helps show our walls
    parameter integer STATE_GAIN  = 8,

    // Enables the Joglekar window when nonzero. Soon will have multiple windowing functions maybe in a version 3.5 or some spin off defintely uses a smple multiplexer and you can just see how the math would change the results
    parameter integer use_joglekar_window = 1,

    // Divides the windowed state increment by 2**window_shift.
    parameter integer window_shift = 8,

    // Replaces a zero window value at either state boundary.
    // This allows the state to move away from a saturated endpoint.
    parameter [7:0] window_floor = 8'd8,

    // Memory file containing the 256 Joglekar window coefficients. Will change properly sometime this weekend as of writing this... cause the file location is very poor... for github atleast
    parameter window_file = "/home/think/Vivado_Project/MemristerVersion3/MemristerVersion3.srcs/sources_1/new/joglekar_window_256x8.mem",

    // Initial signed state coordinate: -128 is the Roff end,
    // +127 is the Ron end, and 0 is approximately the midpoint.
    parameter signed [7:0] X_INIT = 8'sd0
    
)(
    input  wire                     clk, //at 12 Mhz 
    input  wire                     rst, // the reset button
    input  wire signed [15:0]       V_in, // the voltage generated from the internal sine wave generator
    output reg  signed [15:0]       I_out, // Calculated current, scaled by 2^8 found from the memristance and voltage
    output reg  [7:0]               Rmem, // the memrister resistance
    output reg  signed [7:0]        state_x, // the state position from the signed 8 bit
    output reg  [1:0]               dir // changes the direction currently all automatic for the debugging process will be manually triggered eventually
);

    // Physical boundaries for the memristor state
    localparam signed [31:0] X_MIN = (-32'sd128) <<< FRAC_BITS;
    localparam signed [31:0] X_MAX = ( 32'sd127) <<< FRAC_BITS;
    localparam signed [15:0] STATE_GAIN_S = STATE_GAIN;

    // Accumulates smaller bits across the clock cycles until there is enough for state_x to change
    reg signed [31:0] x_q;

    // Temporary values calculated in the combinational block.
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

    // The window contains 256 coefficients, each eight bits wide.
    reg [7:0] joglekar_window [0:255];

    initial begin
        // Initialize the Joglekar window ROM from the selected memory file.
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
            
            // Report the internal state-update direction to the ILA.
            // 00 = idle, 01 = increasing, 10 = decreasing, 11 = attempted movement beyond a saturated boundary.
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

    // Multiply by 256 before division to retain eight fractional bits.
// If Rmem is zero, return zero instead of attempting division.
assign i_calc_scaled = (Rmem != 0)
                     ? ((v_in_32 <<< 8) / Rmem_signed)
                     : 32'sd0;

// Saturate the result to the signed 16-bit output range.
// This prevents an overflow from wrapping to the opposite sign.
assign i_calc = (i_calc_scaled > 32'sd32767)  ? 16'sh7FFF :
                    (i_calc_scaled < -32'sd32768) ? 16'sh8000 : i_calc_scaled[15:0];
                                                   

endmodule
