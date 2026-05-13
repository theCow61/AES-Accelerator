
module aes (
  input clk,
  input rst,
  // from axi memory register
  input [127:0] aes_key,
  input aes_key_write,
  // axi stream read
  input [127:0] read_tdata,
  input read_tvalid,
  input read_tlast,
  output read_tready,
  // axi stream write
  output [127:0] write_tdata,
  output write_tvalid,
  output write_tlast,
  input write_tready
);



wire [3:0] key_select;
wire [127:0] selected_key;

// needs to be cleared once update is registered
reg key_change_pending_key_expansion;
reg key_change_pending_rounder;
wire key_expansion_ack;
wire rounder_key_ack;

wire rounder_refreshing;
wire transaction_status;

key_expansion keys (
  .clk (clk),
  .rst (rst),
  .key (aes_key),
  .round (key_select),
  .round_key (selected_key),
  .pending_key (key_change_pending_key_expansion),
  .rounder_syncing (rounder_refreshing),
  .transaction_ongoing(transaction_status),
  .key_consumed (key_expansion_ack)
);

aes_rounder rounder_1 (
  .clk (clk),
  .rst (rst),
  .key_matrix (selected_key),
  .key_select (key_select),
  .new_key (key_change_pending_rounder),
  .key_syncing (rounder_refreshing),
  .key_ack (rounder_key_ack),
  .transaction_status (transaction_status),
  .data_matrix_in (read_tdata),
  .read_tvalid (read_tvalid),
  .read_tlast (read_tlast),
  .read_tready (read_tready),
  .data_matrix_out (write_tdata),
  .write_tvalid (write_tvalid),
  .write_tlast (write_tlast),
  .write_tready (write_tready)
);



always @(posedge clk) begin
  if (rst) begin
    key_change_pending_key_expansion <= 0;
    key_change_pending_rounder <= 0;
  end
  else begin

    if (rounder_key_ack)
      key_change_pending_rounder <= 0;

    if (key_expansion_ack)
      key_change_pending_key_expansion <= 0;
    

    if (aes_key_write) begin
      key_change_pending_key_expansion <= 1;
      key_change_pending_rounder <= 1;
    end

  end
end


endmodule

