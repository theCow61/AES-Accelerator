`ifndef TYPES_AND_TABLES
`define TYPES_AND_TABLES

`define USE_ROM_INTRINSICS

// treat as column-major [col, row]
typedef logic [3:0][3:0][7:0] aes_matrix_t;

parameter logic [7:0] S_BOX_TABLE [16*16] = {
  'h63, 'h7c, 'h77, 'h7b, 'hf2, 'h6b, 'h6f, 'hc5, 'h30, 'h01, 'h67, 'h2b, 'hfe, 'hd7, 'hab, 'h76,
  'hca, 'h82, 'hc9, 'h7d, 'hfa, 'h59, 'h47, 'hf0, 'had, 'hd4, 'ha2, 'haf, 'h9c, 'ha4, 'h72, 'hc0,
  'hb7,	'hfd,	'h93,	'h26,	'h36,	'h3f,	'hf7,	'hcc,	'h34,	'ha5,	'he5,	'hf1,	'h71,	'hd8,	'h31,	'h15,
  'h04,	'hc7,	'h23,	'hc3,	'h18,	'h96,	'h05,	'h9a,	'h07,	'h12,	'h80,	'he2,	'heb,	'h27,	'hb2,	'h75,
  'h09,	'h83,	'h2c,	'h1a,	'h1b,	'h6e,	'h5a,	'ha0,	'h52,	'h3b,	'hd6,	'hb3,	'h29,	'he3,	'h2f,	'h84,
  'h53,	'hd1,	'h00,	'hed,	'h20,	'hfc,	'hb1,	'h5b,	'h6a,	'hcb,	'hbe,	'h39,	'h4a,	'h4c,	'h58,	'hcf,
  'hd0,	'hef,	'haa,	'hfb,	'h43,	'h4d,	'h33,	'h85,	'h45,	'hf9,	'h02,	'h7f,	'h50,	'h3c,	'h9f,	'ha8,
  'h51,	'ha3,	'h40,	'h8f,	'h92,	'h9d,	'h38,	'hf5,	'hbc,	'hb6,	'hda,	'h21,	'h10,	'hff,	'hf3,	'hd2,
  'hcd,	'h0c,	'h13,	'hec,	'h5f,	'h97,	'h44,	'h17,	'hc4,	'ha7,	'h7e,	'h3d,	'h64,	'h5d,	'h19,	'h73,
  'h60,	'h81,	'h4f,	'hdc,	'h22,	'h2a, 'h90,	'h88,	'h46,	'hee,	'hb8,	'h14,	'hde,	'h5e,	'h0b,	'hdb,
  'he0,	'h32,	'h3a,	'h0a,	'h49,	'h06,	'h24,	'h5c,	'hc2,	'hd3,	'hac,	'h62,	'h91,	'h95,	'he4,	'h79,
  'he7,	'hc8,	'h37,	'h6d,	'h8d,	'hd5,	'h4e,	'ha9,	'h6c,	'h56,	'hf4,	'hea,	'h65,	'h7a,	'hae,	'h08,
  'hba,	'h78,	'h25,	'h2e,	'h1c,	'ha6,	'hb4,	'hc6,	'he8,	'hdd,	'h74,	'h1f,	'h4b,	'hbd,	'h8b,	'h8a,
  'h70,	'h3e,	'hb5,	'h66,	'h48,	'h03,	'hf6,	'h0e,	'h61,	'h35,	'h57,	'hb9,	'h86,	'hc1,	'h1d,	'h9e,
  'he1,	'hf8,	'h98,	'h11,	'h69,	'hd9,	'h8e,	'h94,	'h9b,	'h1e,	'h87,	'he9,	'hce,	'h55,	'h28,	'hdf,
  'h8c,	'ha1, 'h89,	'h0d,	'hbf,	'he6, 'h42,	'h68,	'h41,	'h99,	'h2d,	'h0f,	'hb0,	'h54,	'hbb,	'h16
};

parameter logic [7:0] ROUND_G_CONSTANTS [10] = '{ 'h1, 'h2, 'h4, 'h8, 'h10, 'h20, 'h40, 'h80, 'h1b, 'h36 };

`endif
