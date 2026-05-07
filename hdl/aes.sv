
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

wire key_expansion_key_consumed;

wire [3:0] key_select;
wire [127:0] selected_key;

wire key_expansion_start;
wire rounder_new_key;
wire rounder_key_taken;
wire rounder_update_coming;

key_expansion keys (
  .clk (clk),
  .rst (rst),
  .start_key_expansion (key_change_pending_key_expansion),
  .key (aes_key),
  .key_consumed (key_expansion_key_consumed),
  .round (key_select),
  .round_key (selected_key)
);

aes_rounder rounder_1 (
  .clk (clk),
  .rst (rst),
  .key_matrix (selected_key),
  .key_select (key_select),
  .update_coming (rounder_update_coming),
  .new_key (key_change_pending_rounder),
  .key_taken (rounder_key_taken),
  .data_matrix_in (read_tdata),
  .read_tvalid (read_tvalid),
  .read_tlast (read_tlast),
  .read_tready (read_tready),
  .data_matrix_out (write_tdata),
  .write_tvalid (write_tvalid),
  .write_tlast (write_tlast),
  .write_tready (write_tready)
);

// needs to be cleared once update is registered
reg key_change_pending_key_expansion;
reg key_change_pending_rounder;
assign rounder_update_coming = key_change_pending_key_expansion; // having key expander have a ready signal may be a better way of expressing a lot of this stuff

always @(posedge clk) begin
  if (rst) begin
    key_change_pending_key_expansion <= 0;
    key_change_pending_rounder <= 0;
  end
  else begin

    if (rounder_key_taken)
      key_change_pending_rounder <= 0;

    if (key_change_pending_key_expansion)
      key_change_pending_rounder <= 1; // delayed as key expansion needs to be a cycle ahead of the rounder

    if (key_expansion_key_consumed)
      key_change_pending_key_expansion <= 0;

    if (aes_key_write)
      key_change_pending_key_expansion <= 1;

  end
end


endmodule

