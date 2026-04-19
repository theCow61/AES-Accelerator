`include "tables.svh"

// combinatorial and should all the macs should be parallelized
// pipeline if needed


// 2.39 ns worse total delay I found for this combinatorial piece isolated
// not necessary to pipeline as of now

module combinatorial_matrix_multiplier (
  input aes_matrix_t matrix_in,
  output aes_matrix_t product_matrix
);

function logic [7:0] scale_by_2(input logic [7:0] to_scale);
  return (to_scale[7]) ? ({ to_scale[6:0], 1'b0 } ^ 'h1b) : { to_scale[6:0], 1'b0 };
endfunction

function logic [7:0] scale_by_3(input logic [7:0] to_scale);
  return scale_by_2(to_scale) ^ to_scale;
endfunction

function logic [7:0] row_1_mac(input logic [31:0] to_mac);
  return scale_by_2(to_mac[7:0]) ^ scale_by_3(to_mac[15:8]) ^ to_mac[23:16] ^ to_mac[31:24];
endfunction

function logic [7:0] row_2_mac(input logic [31:0] to_mac);
  return to_mac[7:0] ^ scale_by_2(to_mac[15:8]) ^ scale_by_3(to_mac[23:16]) ^ to_mac[31:24];
endfunction

function logic [7:0] row_3_mac(input logic [31:0] to_mac);
  return to_mac[7:0] ^ to_mac[15:8] ^ scale_by_2(to_mac[23:16]) ^ scale_by_3(to_mac[31:24]);
endfunction

function logic [7:0] row_4_mac(input logic [31:0] to_mac);
  return scale_by_3(to_mac[7:0]) ^ to_mac[15:8] ^ to_mac[23:16] ^ scale_by_2(to_mac[31:24]);
endfunction

// first row of matrix. (matrix from perspective of column major)
// [col, row]

assign product_matrix[0][0] = row_1_mac(matrix_in[0]);
assign product_matrix[1][0] = row_1_mac(matrix_in[1]);
assign product_matrix[2][0] = row_1_mac(matrix_in[2]);
assign product_matrix[3][0] = row_1_mac(matrix_in[3]);

// second row
assign product_matrix[0][1] = row_1_mac(matrix_in[0]);
assign product_matrix[1][1] = row_1_mac(matrix_in[1]);
assign product_matrix[2][1] = row_1_mac(matrix_in[2]);
assign product_matrix[3][1] = row_1_mac(matrix_in[3]);


// third row
assign product_matrix[0][2] = row_1_mac(matrix_in[0]);
assign product_matrix[1][2] = row_1_mac(matrix_in[1]);
assign product_matrix[2][2] = row_1_mac(matrix_in[2]);
assign product_matrix[3][2] = row_1_mac(matrix_in[3]);


// fourth row
assign product_matrix[0][3] = row_1_mac(matrix_in[0]);
assign product_matrix[1][3] = row_1_mac(matrix_in[1]);
assign product_matrix[2][3] = row_1_mac(matrix_in[2]);
assign product_matrix[3][3] = row_1_mac(matrix_in[3]);


endmodule

