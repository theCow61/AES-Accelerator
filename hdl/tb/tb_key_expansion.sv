
module tb_key_expansion (
);

reg clk;
reg rst;
reg start;
byte main_key [16];
byte keys [11][16];
reg round_idx;

byte dut_round_key [16];

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
  main_key = 0;
  round_idx = 0;
  #33; // a little offset to reduce ambiguity in waveforms
  rst = 0;
  #10;

  $readmemh("test1/expanded_keys", keys);

  main_key = keys[0]; // have key and start on same cycle
  start = 1;
  #10;
  main_key = 0; // remove key to make sure it's not dependent on it
  round_idx = 0;
  start = 0;
  // test founding key is correct
  if (dut_round_key == keys[0]) begin
    $display("Founding key good.");
  end
  else
    $display("Fail: Founding key.");

  #10;

  for (int i = 1; i < 11; i = i + 1) begin
    round_idx = i;
    if (dut_round_key == keys[i])
      $display("Expanded key %d good.", i);
    else
      $display("Fail: Expanded key %d.", i);

    #10;
  end

end

endmodule


