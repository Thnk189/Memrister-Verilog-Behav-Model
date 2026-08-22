`timescale 1ns / 1ps

module rom_async #(
    parameter WIDTH  = 8,
    parameter DEPTH  = 64,
    parameter INIT_F = "sine_table_64x8.mem"
)(
    input  wire [5:0]       addr,
    output reg  [WIDTH-1:0] data
);
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    initial begin
        $readmemh(INIT_F, mem);
    end

    always @(*) begin
        data = mem[addr];
    end
endmodule


module sine_table #(
    parameter ROM_DEPTH = 64,
    parameter ROM_WIDTH = 8,
    parameter ROM_FILE  = "sine_table_64x8.mem"
)(
    input  wire [7:0]          id,
    output reg  signed [15:0]  data
);

    reg [5:0]  tab_id;
    wire [ROM_WIDTH-1:0] tab_data;
    reg [1:0]  quad;

    rom_async #(
        .WIDTH(ROM_WIDTH),
        .DEPTH(ROM_DEPTH),
        .INIT_F(ROM_FILE)
    ) sine_rom (
        .addr(tab_id),
        .data(tab_data)
    );

    always @(*) begin
        quad = id[7:6];
        case (quad)
            2'b00:   tab_id = id[5:0];
            2'b01:   tab_id = (2*ROM_DEPTH - id[5:0]) % 64;
            2'b10:   tab_id = (id[5:0] - 2*ROM_DEPTH) % 64;
            2'b11:   tab_id = (4*ROM_DEPTH - id[5:0]) % 64;
            default: tab_id = 6'b0;
        endcase

        if (id == ROM_DEPTH) begin
            data = 16'h0100;
        end else if (id == 3*ROM_DEPTH) begin
            data = 16'hFF00;
        end else begin
            if (quad[1] == 1'b0)
                data = {8'h00, tab_data};
            else
                data = 16'h0000 - {8'h00, tab_data};
        end
    end
endmodule
