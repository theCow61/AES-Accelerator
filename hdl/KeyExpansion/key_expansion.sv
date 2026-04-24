
// Considering that round_key has to go to many different PEs,
// the output of this module should be pipelined as much as needed to let the
// router space things out such that there isn't a ton of interconnect delay

// round key of round n should be ready in n cycles. mind the timing instead
// of implementing logic for stalling or giving status.


module key_expansion (
  input clk,
  input rst,
  input start_key_expansion,
  input aes_matrix_t key,
  input [3:0] round,
  output aes_matrix_t round_key
);

aes_matrix_t expanded_keys [11];


reg [3:0] round_counter_previous;
reg [3:0] round_counter; // so to not use an adder

// combinatorial. maybe have registers to reduce delay
assign round_key = expanded_keys[round];

typedef enum logic [1:0] {
  IDLE,
  ROUND_KEY_GENERATION,
} key_expansion_state_t;

key_expansion_state_t state;

function logic [31:0] g_of_column(input logic [31:0] column, input logic [3:0] g_round);
  return { S_BOX_TABLE[column[7:0]], S_BOX_TABLE[column[31:24]], S_BOX_TABLE[column[23:16]], S_BOX_TABLE[15:8] ^ ROUND_G_CONSTANTS[g_round] };
endfunction

function aes_matrix_t expand_key(input aes_matrix_t previous, input logic [3:0] g_round);
  logic [31:0] g_last_column = g_of_column(previous[3], g_round);

  // maybe pipeline this
  logic [31:0] new_column_1 = previous[0] ^ g_last_column;
  logic [31:0] new_column_2 = previous[1] ^ new_column_1;
  logic [31:0] new_column_3 = previous[2] ^ new_column_2;
  logic [31:0] new_column_4 = previous[3] ^ new_column_3;

  return { new_column_4, new_column_3, new_column_2, new_column_1 };
endfunction


always @(posedge clk) begin
  if (rst) begin
    round_counter_previous <= 0;
    round_counter <= 1;
    state <= IDLE;
  end
  else begin

    case (state)
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
        expanded_keys[round_counter] <= expand_key(expanded_keys[round_counter_previous], round_counter_previous);

        // don't let this be an adder. use two counters if needed
        round_counter_previous <= round_counter_previous + 1;
        round_counter <= round_counter + 1;

        if (round_counter == 10) // all round keys should be generated
          state <= IDLE;
      end
    endcase

  end
end


endmodule

