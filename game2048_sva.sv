module game2048_sva_bb (
  input logic clk, rst_n, ena,
  input logic [7:0] ui_in, uo_out, uio_in, uio_out, uio_oe
);
  logic hsync, vsync;
  logic [5:0] rgb;
  assign hsync = uo_out[7];
  assign vsync = uo_out[3];
  assign rgb   = {uo_out[0], uo_out[4], uo_out[1], uo_out[5], uo_out[2], uo_out[6]};

  // Checker-local "reset done" - no RTL signals used
  logic [2:0] rst_cnt;
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n)              rst_cnt <= '0;
    else if (rst_cnt != 3'd7) rst_cnt <= rst_cnt + 1'b1;
  wire rst_done = (rst_cnt == 3'd7);

  // 4.3: unused bidirectional pins tied to zero (constant, no disable)
  a_uio_zero: assert property (@(posedge clk) uio_out == 8'h00 && uio_oe == 8'h00);

  // Outputs known after reset
  a_no_x: assert property (@(posedge clk) disable iff (!rst_done)
                           !$isunknown(uo_out));

  // VGA timing, §5.4 / VGA table
  a_hs_w: assert property (@(posedge clk) disable iff (!rst_done)
            $fell(hsync) |=> (!hsync)[*95] ##1 hsync);
  a_hs_p: assert property (@(posedge clk) disable iff (!rst_done)
            $fell(hsync) |=> (!$fell(hsync))[*799] ##1 $fell(hsync));
  a_vs_w: assert property (@(posedge clk) disable iff (!rst_done)
            $fell(vsync) |=> (!vsync)[*1599] ##1 vsync);
  a_vs_p: assert property (@(posedge clk) disable iff (!rst_done)
            $fell(vsync) |=> (!$fell(vsync))[*419999] ##1 $fell(vsync));
endmodule