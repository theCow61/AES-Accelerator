`include "tables.svh"

module aes_rounder (
  input clk,
  input rst,
  input start,
  input aes_matrix_t data_matrix_in,
  input aes_matrix_t founding_key,
  input aes_matrix_t key_matrix,
  output [3:0] key_select, // as pipeline fills up, get the keys. This instead of a mess of interconnect. Always keep this as 0 by default so the first key can be ready
  output aes_matrix_t data_matrix_out,

  // axi stream read
  input read_tvalid,
  input read_tlast,
  output read_tready,

  // axi stream write
  output write_tvalid,
  output write_tlast,
  input write_tready
);

aes_matrix_t in_states [10];
aes_matrix_t round_keys [11]; // store local copy of round keys from key expansion to reduce routing delay
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

assign key_select = pipeline_startup_counter;

reg filling_up;

// fill up needs to be ahead of rounding
// instead of having a seperate parallel bus for founding key, just allow
// the key expansion to be ahead maybe a little more. this extra latency
// might not matter if we assume the key being set into register and the
// start of streaming data has a couple cycle inbetween anyways.
// this may be better than the routing impact of the founding key being routed
always @(posedge clk) begin
  if (rst) begin
    pipeline_startup_counter <= 0;
    filling_up <= 0;
  end
  else begin


    if (pipeline_fill_up || filling_up) begin
      filling_up <= 1;

      pipeline_startup_counter <= pipeline_startup_counter + 1;
      round_keys[pipeline_startup_counter] <= key_matrix;
    end
    else
      pipeline_startup_counter <= 1;

    if (pipeline_startup_counter == 10) begin // keys should be finished writing
      pipeline_startup_counter <= 1;
      filling_up <= 0;
    end
  end
end

// tready = we aren't stalling
// tvalid = check parallel pipeline
// tlast = check parallel pipeline

typedef struct {
  logic valid;
  logic last;
} metadata_t;

metadata_t parallel_status_pipeline [11];

assign write_tlast = parallel_status_pipeline[$size(parallel_status_pipeline) - 1].last;
assign write_tvalid = parallel_status_pipeline[$size(parallel_status_pipeline) - 1].valid;

wire stall;
assign stall = ~write_tready;
assign read_tready = ~stall;


always @(posedge clk) begin
  if (rst) begin
    parallel_status_pipeline <= '{ default: '0 };
  end
  else begin
    if (!stall) begin
      parallel_status_pipeline[0] <= '{ read_tvalid, read_tlast };
      parallel_status_pipeline[1] <= parallel_status_pipeline[0];
      parallel_status_pipeline[2] <= parallel_status_pipeline[1];
      parallel_status_pipeline[3] <= parallel_status_pipeline[2];
      parallel_status_pipeline[4] <= parallel_status_pipeline[3];
      parallel_status_pipeline[5] <= parallel_status_pipeline[4];
      parallel_status_pipeline[6] <= parallel_status_pipeline[5];
      parallel_status_pipeline[7] <= parallel_status_pipeline[6];
      parallel_status_pipeline[8] <= parallel_status_pipeline[7];
      parallel_status_pipeline[9] <= parallel_status_pipeline[8];
      parallel_status_pipeline[10] <= parallel_status_pipeline[9];

      in_states[0] <= data_matrix_in ^ round_keys[0];
      in_states[1] <= out_states[0];
      in_states[2] <= out_states[1];
      in_states[3] <= out_states[2];
      in_states[4] <= out_states[3];
      in_states[5] <= out_states[4];
      in_states[6] <= out_states[5];
      in_states[7] <= out_states[6];
      in_states[8] <= out_states[7];
      in_states[9] <= out_states[8];
      data_matrix_out <= out_states[9];

    end
  end
end


endmodule

