
`include "tables.svh"

module tb_key_expansion (
);

reg clk;
reg rst;
reg start;
aes_matrix_t main_key;
byte keys [11][16];
aes_matrix_t keys_casted [11]; // cant do direct cast because of how it orders it
reg [3:0] round_idx;

typedef byte byte_array_t [16];
aes_matrix_t dut_round_key;


key_expansion DUT (
  .clk (clk),
  .rst (rst),
  .start_key_expansion (start),
  .key (main_key),
  .round (round_idx),
  .round_key (dut_round_key)
);


initial clk = 0;
always #5 clk = ~clk; // period of 10


initial begin
  rst = 1;
  main_key = '{default: 0};
  round_idx = 0;
  #33; // a little offset to reduce ambiguity in waveforms
  rst = 0;
  #10;

  $readmemh("expanded_keys", keys);
  
  for (int i = 0; i < 11; i = i + 1) begin
    keys_casted[i] = { << byte {keys[i]}};
  end

  main_key = keys_casted[0]; // have key and start on same cycle
  $display("%X", aes_matrix_t'(main_key));
  start = 1;
  #10;
  main_key = '{default: 0}; // remove key to make sure it's not dependent on it
  round_idx = 0;
  start = 0;
  // test founding key is correct
  if (dut_round_key == keys_casted[0]) begin
    $display("Founding key good.");
  end
  else
    $display("Fail: Founding key.");

  #10;

  for (int i = 1; i < 11; i = i + 1) begin
    round_idx = i;
    #0;
    if (dut_round_key == keys_casted[i])
      $display("Expanded key %d good.", i);
    else
      $display("Fail: Expanded key %d.", i);

    #10;
  end
  
  $finish();
end

endmodule


