// meets 250 MHz with slack of 0.03

`include "tables.svh"

module aes_round_pe #(parameter MIX_COLUMNS = 1) (
  input aes_matrix_t state_in,
  input aes_matrix_t round_key,
  output aes_matrix_t state_out
);

wire aes_matrix_t shifted_and_substituted;


wire aes_matrix_t column_mixed;

combinatorial_matrix_multiplier column_mixer (
  .matrix_in (shifted_and_substituted),
  .product_matrix (column_mixed)
);

// MIX_COLUMNS evaluation should be compile time
assign state_out = MIX_COLUMNS ? column_mixed ^ round_key : shifted_and_substituted ^ round_key;

// S_BOX_TABLE ROM lookup might need to be pipelined

/*
// first row has no subsitution (column major matrix)
assign shifted_and_substituted[0][0] = S_BOX_TABLE[state_in[0][0]];
assign shifted_and_substituted[1][0] = S_BOX_TABLE[state_in[1][0]];
assign shifted_and_substituted[2][0] = S_BOX_TABLE[state_in[2][0]];
assign shifted_and_substituted[3][0] = S_BOX_TABLE[state_in[3][0]];

// second row
assign shifted_and_substituted[0][1] = S_BOX_TABLE[state_in[1][1]];
assign shifted_and_substituted[1][1] = S_BOX_TABLE[state_in[2][1]];
assign shifted_and_substituted[2][1] = S_BOX_TABLE[state_in[3][1]];
assign shifted_and_substituted[3][1] = S_BOX_TABLE[state_in[0][1]];

// third row
assign shifted_and_substituted[0][2] = S_BOX_TABLE[state_in[2][2]];
assign shifted_and_substituted[1][2] = S_BOX_TABLE[state_in[3][2]];
assign shifted_and_substituted[2][2] = S_BOX_TABLE[state_in[0][2]];
assign shifted_and_substituted[3][2] = S_BOX_TABLE[state_in[1][2]];

// fourth row
assign shifted_and_substituted[0][3] = S_BOX_TABLE[state_in[3][3]];
assign shifted_and_substituted[1][3] = S_BOX_TABLE[state_in[0][3]];
assign shifted_and_substituted[2][3] = S_BOX_TABLE[state_in[1][3]];
assign shifted_and_substituted[3][3] = S_BOX_TABLE[state_in[2][3]];
*/

// first row has no substitution (column major matrix)
lookup_table_256x8 #( .lookup_data (S_BOX_TABLE)) byte0_substitution (.addr (state_in[0][0]), .data (shifted_and_substituted[0][0]));
lookup_table_256x8 #( .lookup_data (S_BOX_TABLE)) byte4_substitution (.addr (state_in[1][0]), .data (shifted_and_substituted[1][0]));
lookup_table_256x8 #( .lookup_data (S_BOX_TABLE)) byte8_substitution (.addr (state_in[2][0]), .data (shifted_and_substituted[2][0]));
lookup_table_256x8 #( .lookup_data (S_BOX_TABLE)) byte12_substitution (.addr (state_in[3][0]), .data (shifted_and_substituted[3][0]));

// second row
lookup_table_256x8 #( .lookup_data (S_BOX_TABLE)) byte1_substitution (.addr (state_in[1][1]), .data (shifted_and_substituted[0][1]));
lookup_table_256x8 #( .lookup_data (S_BOX_TABLE)) byte5_substitution (.addr (state_in[2][1]), .data (shifted_and_substituted[1][1]));
lookup_table_256x8 #( .lookup_data (S_BOX_TABLE)) byte9_substitution (.addr (state_in[3][1]), .data (shifted_and_substituted[2][1]));
lookup_table_256x8 #( .lookup_data (S_BOX_TABLE)) byte13_substitution (.addr (state_in[0][1]), .data (shifted_and_substituted[3][1]));

// third row
lookup_table_256x8 #( .lookup_data (S_BOX_TABLE)) byte2_substitution (.addr (state_in[2][2]), .data (shifted_and_substituted[0][2]));
lookup_table_256x8 #( .lookup_data (S_BOX_TABLE)) byte6_substitution (.addr (state_in[3][2]), .data (shifted_and_substituted[1][2]));
lookup_table_256x8 #( .lookup_data (S_BOX_TABLE)) byte10_substitution (.addr (state_in[0][2]), .data (shifted_and_substituted[2][2]));
lookup_table_256x8 #( .lookup_data (S_BOX_TABLE)) byte14_substitution (.addr (state_in[1][2]), .data (shifted_and_substituted[3][2]));

// fourth row
lookup_table_256x8 #( .lookup_data (S_BOX_TABLE)) byte3_substitution (.addr (state_in[3][3]), .data (shifted_and_substituted[0][3]));
lookup_table_256x8 #( .lookup_data (S_BOX_TABLE)) byte7_substitution (.addr (state_in[0][3]), .data (shifted_and_substituted[1][3]));
lookup_table_256x8 #( .lookup_data (S_BOX_TABLE)) byte11_substitution (.addr (state_in[1][3]), .data (shifted_and_substituted[2][3]));
lookup_table_256x8 #( .lookup_data (S_BOX_TABLE)) byte15_substitution (.addr (state_in[2][3]), .data (shifted_and_substituted[3][3]));

endmodule

