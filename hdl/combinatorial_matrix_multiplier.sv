
// combinatorial and should all the macs should be parallelized
// pipeline if needed


// 2.39 ns worse total delay I found for this combinatorial piece isolated
// not necessary to pipeline as of now

module combinatorial_matrix_multiplier (
  input [127:0] matrix_in,
  output [127:0] product_matrix
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

// row one of matrix. (matrix from perspective of column major)
assign product_matrix[7:0] = row_1_mac(matrix_in[31:0])
assign product_matrix[39:32] = row_1_mac(matrix_in[63:32])
assign product_matrix[71:64] = row_1_mac(matrix_in[95:64])
assign product_matrix[103:96] = row_1_mac(matrix_in[127:96])


// row two
assign product_matrix[15:8] = row_2_mac(matrix_in[31:0])
assign product_matrix[47:40] = row_2_mac(matrix_in[63:32])
assign product_matrix[79:72] = row_2_mac(matrix_in[95:64])
assign product_matrix[111:104] = row_2_mac(matrix_in[127:96])


// row three
assign product_matrix[23:16] = row_2_mac(matrix_in[31:0])
assign product_matrix[55:48] = row_2_mac(matrix_in[63:32])
assign product_matrix[87:80] = row_2_mac(matrix_in[95:64])
assign product_matrix[119:112] = row_2_mac(matrix_in[127:96])

// row three
assign product_matrix[31:24] = row_2_mac(matrix_in[31:0])
assign product_matrix[63:56] = row_2_mac(matrix_in[63:32])
assign product_matrix[95:88] = row_2_mac(matrix_in[95:64])
assign product_matrix[127:120] = row_2_mac(matrix_in[127:96])


endmodule

