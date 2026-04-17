
// Considering that round_key has to go to many different PEs,
// the output of this module should be pipelined as much as needed to let the
// router space things out such that there isn't a ton of interconnect delay

// round key of round n should be ready in n cycles. mind the timing instead
// of implementing logic for stalling or giving status.


module key_expansion (
  input clk,
  input rst,
  input start_key_expansion,
  input [127:0] key,
  input [3:0] round,
  output [127:0] round_key
);


reg [127:0] expanded_keys [0:10];

reg [4:0] round_counter_previous;
reg [4:0] round_counter; // so to not use an adder

// combinatorial.
assign round_key = expanded_keys[round];

typedef enum logic [1:0] {
  IDLE,
  ROUND_KEY_GENERATION,
} key_expansion_state_t;

key_expansion_state_t state;


always @(posedge clk) begin
  if (rst) begin
    round_counter_previous <= 0;
    round_counter <= 1;
    state <= IDLE;
  end
  else begin

    case (state) begin
      IDLE: begin
        if (start_key_expansion) begin
          // don't hardwire expanded_keys[0] to the key as the key may change
          // later on (for a different aes operation)
          expanded_keys[0] <= key;
          state <= ROUND_KEY_GENERATION;
          round_counter_previous <= 0;
          round_counter <= 1;
        end
      end
      ROUND_KEY_GENERATION: begin

        // temps
        logic [31:0] last_column = expanded_keys[round_counter_previous][127:96];
        logic [31:0] g_last_column = { S_BOX_TABLE[last_column[7:0]], S_BOX_TABLE[last_column[31:24]], S_BOX_TABLE[last_column[23:16]], S_BOX_TABLE[last_column[15:8]] ^ ROUND_G_CONSTANTS[round_counter_previous] };

        // maybe pipeline this
        logic [31:0] new_column_1 = expanded_keys[round_counter_previous][31:0] ^ g_last_column;
        logic [31:0] new_column_2 = expanded_keys[round_counter_previous][63:32] ^ new_column_1;
        logic [31:0] new_column_3 = expanded_keys[round_counter_previous][95:64] ^ new_column_2;
        logic [31:0] new_column_4 = expanded_keys[round_counter_previous][127:96] ^ new_column_3;

        // don't let this be an adder. use two counters if needed
        expanded_keys[round_counter][31:0] <= new_column_1;
        expanded_keys[round_counter][63:32] <= new_column_2;
        expanded_keys[round_counter][95:64] <= new_column_3;
        expanded_keys[round_counter][127:96] <= new_column_4;

        round_counter_previous <= round_counter_previous + 1;
        round_counter <= round_counter + 1;

        if (round_counter == 10) // all round keys should be generated
          state <= IDLE;
      end
    endcase

  end
end


endmodule

