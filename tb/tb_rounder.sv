
`include "tables.svh"

module tb_rounder (
);

reg clk;
reg rst;


initial clk = 0;
always #5 clk = ~clk; // period of 10

aes_matrix_t key;
reg key_write;
aes_matrix_t dut_read_tdata;
reg dut_read_tvalid;
reg dut_read_tlast;
wire dut_read_tready;
aes_matrix_t dut_write_tdata;
wire dut_write_tvalid;
wire dut_write_tlast;
reg dut_write_tready;


aes DUT (
    .clk (clk),
    .rst (rst),
    .aes_key (key),
    .aes_key_write (key_write),
    .read_tdata (dut_read_tdata),
    .read_tvalid (dut_read_tvalid),
    .read_tlast (dut_read_tlast),
    .read_tready (dut_read_tready),
    .write_tdata (dut_write_tdata),
    .write_tvalid (dut_write_tvalid),
    .write_tlast (dut_write_tlast),
    .write_tready (dut_write_tready)
);

byte key_read [16];
byte text_read [16];
byte cipher_read [16];

aes_matrix_t key_casted;
aes_matrix_t text_casted;
aes_matrix_t cipher_casted;

initial begin
  rst = 1;
  #33; // a little offset to reduce ambiguity in waveforms
  rst = 0;
  #10;
  
  $readmemh("key", key_read);
  $readmemh("text", text_read);
  $readmemh("cipher", cipher_read);
  
  key_casted = { << byte {key_read}};
  text_casted = { << byte {text_read}};
  cipher_casted = { << byte {cipher_read}};


end


endmodule


