
module tb_rounder (
);

reg clk;
reg rst;
string plain_text;
string key;
byte expanded_keys [128][11];

initial clk = 0;
always #5 clk = ~clk; // period of 10

initial begin
  rst = 1;
  #33; // a little offset to reduce ambiguity in waveforms
  rst = 0;
  #10;

  plain_text = "hello hellohello";
  key = "aaa aaa aaa aaaa";





end


endmodule


