`include "tables.svh"


// round units have there own corresponding local round key copy that gets filled up sequentially
// this allows key expansion to occur for new keys while an encryption is ongoing as the current round key values are stored
// this also prevents needing to have a bunch of large busses going everywhere which may increase routing delay
// instead we use a single bus from the key expansion unit which can fill up the local buffers simulatanously
// as we fill up the pipeline (starting an encryption). Key expansion can occur at the same time as the pipeline is filling up
// except the key expansion has to be ahead by atleast a cycle


module aes_rounder (
  input clk,
  input rst,
  input aes_matrix_t key_matrix,
  output [3:0] key_select, // as pipeline fills up, get the keys. This instead of a mess of interconnect. Always keep this as 0 by default so the first key can be ready
  input new_key, // new key available but not necessarily valid to resync keys up yet (from the key expansion)
  output key_syncing,
  output key_ack,
  output transaction_status,

  // axi stream read
  input aes_matrix_t data_matrix_in,
  input read_tvalid,
  input read_tlast,
  output read_tready,

  // axi stream write
  output aes_matrix_t data_matrix_out,
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

typedef enum logic {
    TRANSACTION_IDLE = 0,
    ONGOING = 1
} transaction_state_t;
transaction_state_t transaction_state;
assign transaction_status = transaction_state == ONGOING;
// it is not sufficient to just look at tvalid as there may be stalls throughout the transactions from the data source
always @(posedge clk) begin
    if (rst)
        transaction_state <= TRANSACTION_IDLE;
    else begin
        case (transaction_state)
            TRANSACTION_IDLE: begin
                if (read_tvalid)
                    transaction_state <= ONGOING;
            end
            ONGOING: begin
                // write_tlast and write_tvalid should propogate from read_tlast and read_tvalid
                if (write_tlast && write_tvalid && write_tready)
                    transaction_state <= TRANSACTION_IDLE;
            end
        endcase
    end
end


typedef enum logic {
    IDLE = 0,
    SYNCING = 1
} refresh_state_t;
refresh_state_t refresh_state;
reg [3:0] key_syncing_counter;
assign key_select = key_syncing_counter;
assign key_ack = new_key & (transaction_state == TRANSACTION_IDLE);
assign key_syncing = refresh_state == SYNCING;
always @(posedge clk) begin
    if (rst) begin
        refresh_state <= IDLE;
        key_syncing_counter <= 0;
    end
    else begin
        // new_key refers to when a new key has came but it doesn't mean that it is available to us from the key expansion to use yet
        // new_key is asserted after the write signal so if there is a new_key and tvalid appears at the same time (while transaction
        // is low as it hasn't been registered yet), the new
        // transaction should actually take the new key because the write that caused the new_key predated the tvalid
        case (refresh_state)
            IDLE: begin
                key_syncing_counter <= 0;
                if (new_key && transaction_state == TRANSACTION_IDLE) begin
                    refresh_state <= SYNCING;
                    // don't load first key yet as this needs to be atleast one cycle behind the kex expansion
                end
            end
            SYNCING: begin        
                key_syncing_counter <= key_syncing_counter + 1;
                round_keys[key_syncing_counter] <= key_matrix;
                
                // finishing key syncing
                if (key_syncing_counter == 10) begin
                    key_syncing_counter <= 0;
                    refresh_state <= IDLE;
                end
                
                // restart. Expect multiple "new_key"s for a single new key considering that
                // the register writes aren't atomic and a key takes up 4 of our axi registers
                if (new_key && transaction_state == TRANSACTION_IDLE) begin
                    refresh_state <= SYNCING;
                    key_syncing_counter <= 0;
                end
            end
        endcase
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
assign stall = (~write_tready & write_tvalid) | (new_key & (transaction_state == TRANSACTION_IDLE)) | ((refresh_state == SYNCING) & key_syncing_counter == 0);
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
      data_matrix_out <= out_states[9]; // maybe don't pipeline output of last; it has less logic than the other anyways

    end
  end
end


endmodule

