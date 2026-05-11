
// Considering that round_key has to go to many different PEs,
// the output of this module should be pipelined as much as needed to let the
// router space things out such that there isn't a ton of interconnect delay

// round key of round n should be ready in n cycles. mind the timing instead
// of implementing logic for stalling or giving status.

`include "tables.svh"

module key_expansion (
  input clk,
  input rst,
  input aes_matrix_t key,
  input [3:0] round,
  output aes_matrix_t round_key,
  
  input pending_key,
  input rounder_syncing,
  input transaction_ongoing,
  output key_consumed
);

aes_matrix_t expanded_keys [11];

reg [3:0] round_counter_previous;
reg [3:0] round_counter; // so to not use an adder
reg [7:0] round_constant;

// combinatorial. maybe have registers to reduce delay
// part of critical path. using a non combinatorial port read
// may require us to have an extra cycle where the key expansion is ahead of the rounder.
// considering that the timing of this critical path is similiar to that of the next most
// critical paths, fixing this with adding a potential extra cycle of latency while just
// having a different, but almost same delay, critical path doesn't seem worth it
assign round_key = expanded_keys[round];


wire [7:0] expansion_sbox_0_data;
wire [7:0] expansion_sbox_1_data;
wire [7:0] expansion_sbox_2_data;
wire [7:0] expansion_sbox_3_data;


function automatic logic [31:0] g_of_column(/*input logic [31:0] column, */input logic [3:0] g_round);
  //return { S_BOX_TABLE[column[7:0]], S_BOX_TABLE[column[31:24]], S_BOX_TABLE[column[23:16]], S_BOX_TABLE[column[15:8]] ^ ROUND_G_CONSTANTS[g_round] };
  //return { expansion_sbox_0_data, expansion_sbox_3_data, expansion_sbox_2_data, expansion_sbox_1_data ^ ROUND_G_CONSTANTS[g_round] };
  return { expansion_sbox_0_data, expansion_sbox_3_data, expansion_sbox_2_data, expansion_sbox_1_data ^ round_constant };
endfunction

function automatic aes_matrix_t expand_key(input aes_matrix_t previous, input logic [3:0] g_round);
  //logic [31:0] g_last_column = g_of_column(previous[3], g_round);
  logic [31:0] g_last_column = g_of_column(g_round);

  // maybe pipeline this
  logic [31:0] new_column_1 = previous[0] ^ g_last_column;
  logic [31:0] new_column_2 = previous[1] ^ new_column_1;
  logic [31:0] new_column_3 = previous[2] ^ new_column_2;
  logic [31:0] new_column_4 = previous[3] ^ new_column_3;

  return { new_column_4, new_column_3, new_column_2, new_column_1 };
endfunction

typedef enum logic [1:0] {
  IDLE,
  ROUND_KEY_GENERATION
} key_expansion_state_t;

key_expansion_state_t state;

assign key_consumed = pending_key & ~(rounder_syncing & transaction_ongoing);

aes_matrix_t previous_key;

lookup_table_256x8 #( .lookup_data (S_BOX_TABLE)) expansion_sbox_1 (.addr (previous_key[3][1]), .data (expansion_sbox_1_data));
lookup_table_256x8 #( .lookup_data (S_BOX_TABLE)) expansion_sbox_2 (.addr (previous_key[3][2]), .data (expansion_sbox_2_data));
lookup_table_256x8 #( .lookup_data (S_BOX_TABLE)) expansion_sbox_3 (.addr (previous_key[3][3]), .data (expansion_sbox_3_data));
lookup_table_256x8 #( .lookup_data (S_BOX_TABLE)) expansion_sbox_0 (.addr (previous_key[3][0]), .data (expansion_sbox_0_data));

always @(posedge clk) begin
  if (rst) begin
    previous_key <= 0;
    round_counter_previous <= 0;
    round_counter <= 1;
    state <= IDLE;
  end
  else begin

    case (state)
      IDLE: begin
        if (pending_key && !(rounder_syncing && transaction_ongoing)) begin
          // don't hardwire expanded_keys[0] to the key as the key may change
          // later on (for a different aes operation)
          previous_key <= key;
          expanded_keys[0] <= key;
          state <= ROUND_KEY_GENERATION;
          round_counter_previous <= 0;
          round_counter <= 1;
          round_constant <= ROUND_G_CONSTANTS[0];
        end
      end
      ROUND_KEY_GENERATION: begin
        // the synthesizer doesn't know that round_counter should ALWAYS be +1 ahead of round_counter_previous which seems to make a lot more logic
        // then necessary
        //expanded_keys[round_counter] <= expand_key(expanded_keys[round_counter_previous], round_counter_previous);
        
        // use this instead to avoid above issue. -4 ns slack caused by the above went away with this
        expanded_keys[round_counter] <= expand_key(previous_key, round_counter_previous);
        previous_key <= expand_key(previous_key, round_counter_previous);
        round_constant <= ROUND_G_CONSTANTS[round_counter];
        
        
        // don't let this be an adder. use two counters if needed
        round_counter_previous <= round_counter_previous + 1;
        round_counter <= round_counter + 1;

        if (round_counter == 10) // all round keys should be generated
          state <= IDLE;
        
        if (pending_key && !(rounder_syncing && transaction_ongoing)) begin
            // be able to restart the process considering that the key register is multiple
            // words and isn't atomic so there could be a variable amount of writes
            // that happen to that register which  may trigger the key generation
            state <= ROUND_KEY_GENERATION;
            previous_key <= key;
            expanded_keys[0] <= key;
            round_counter <= 1;
            round_counter_previous <= 0;
            round_constant <= ROUND_G_CONSTANTS[0];
        end
      end
    endcase

  end
end


endmodule

