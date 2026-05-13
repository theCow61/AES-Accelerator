`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.05.2026 21:03:08
// Design Name: 
// Module Name: lookup_table
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module lookup_table_256x8 #( parameter logic [7:0] lookup_data [256] = '{default: 0}) (
    input [7:0] addr,
    output [7:0] data
    );
    
    function automatic logic [255:0] ith_bit_from_entries(input int i);
        logic [255:0] ith_bit_bus;
        for (int j = 0; j < 256; j = j + 1) begin
            ith_bit_bus[j] = lookup_data[j][i];
        end
        return ith_bit_bus;
    endfunction
    
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin
            ROM256X1 #(
                .INIT(ith_bit_from_entries(i))
            ) rombit (
                .O (data[i]),
                .A0 (addr[0]),
                .A1 (addr[1]),
                .A2 (addr[2]),
                .A3 (addr[3]),
                .A4 (addr[4]),
                .A5 (addr[5]),
                .A6 (addr[6]),
                .A7 (addr[7])
            );
        end
    endgenerate
    
    
endmodule
