`include "tables.svh"

module aes_rounder (
  input clk,
  input rst,
  input start,
  input aes_matrix_t data_matrix_in,
  input aes_matrix_t key_matrix,
  output [3:0] key_select, // as pipeline fills up, get the keys. This instead of a mess of interconnect. Always keep this as 0 by default so the first key can be ready
  output aes_matrix_t data_matrix_out
);

aes_matrix_t in_states [10];
aes_matrix_t round_keys [11];
aes_matrix_t out_states [10];

genvar i;
generate
  for (i = 0; i < 9; i = i + 1) begin : generate_rounds
    aes_round_pe #(.MIX_COLUMNS(1)) round (
      .state_in (in_states[i]),
      .round_key (round_keys[i + 1]),
      .state_out (out_states[i])
    );
  end
  aes_round_pe #(.MIX_COLUMNS(0)) round_last (
    .state_in (in_states[9]),
    .round_key (round_keys[10]),
    .state_out (out_states[9])
  );
endgenerate

reg [3:0] pipeline_startup_counter;


always @* begin
  round = 0;
  if (start) begin
    round = pipeline_startup_counter;
  end
end

always @(posedge clk) begin
  if (rst) begin
    pipeline_startup_counter <= 1;
  end
  else begin
    data_matrix_out <= out_states[9];
    in_states[9] <= out_states[8];
    in_states[8] <= out_states[7];
    in_states[7] <= out_states[6];
    in_states[6] <= out_states[5];
    in_states[5] <= out_states[4];
    in_states[4] <= out_states[3];
    in_states[3] <= out_states[2];
    in_states[2] <= out_states[1];
    in_states[1] <= out_states[0];
    in_states[0] <= data_matrix_in ^ round_keys[0];


    if (start) begin
      pipeline_startup_counter <= pipeline_startup_counter + 1;
    end

  end


end

endmodule

