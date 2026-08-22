`timescale 1ns / 1ps

module phase_accumulator #(
    parameter CLK_HZ    = 12_000_000, // Matches the physical Arty S7 crystal clock
    parameter SINE_HZ   = 1,
    parameter ROM_DEPTH = 64,
    parameter ROM_WIDTH = 8,
    parameter ROM_FILE  = "sine_table_64x8.mem"
)(
    input  wire               clk,        // Driven directly by physical pin R2
    input  wire               rst,
    output wire signed [15:0] sine_out
);

    // Calculate the exact stepping increment needed for a 1Hz wave at 12MHz
    localparam integer PHASE_INC = (32'hFFFFFFFF / CLK_HZ) * SINE_HZ;

    reg [31:0] phase;
    wire [7:0] table_id;

    // Direct clocking loop using the board's native 12MHz clock line
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            phase <= 32'b0;
        end else begin
            phase <= phase + PHASE_INC;
        end
    end

    // Take the top 8 bits to index our 256-step full wave (from 64-step quarter ROM)
    assign table_id = phase[31:24];

    // Instantiation of the sine table module
    sine_table #(
        .ROM_DEPTH(ROM_DEPTH),
        .ROM_WIDTH(ROM_WIDTH),
        .ROM_FILE(ROM_FILE)
    ) sine_inst (
        .id(table_id),
        .data(sine_out)
    );

endmodule
