`timescale 1ns/1ps

`include "uvm_macros.svh"
`include "defines.svh"
`include "game2048_sva.sv"

module tb_top;

  import uvm_pkg::*;
  import game_pkg::*;

  logic clk = 1'b0;
  logic rst_n = 1'b0;

  always #(`CLK_PERIOD_NS / 2.0)
    clk = ~clk;

  game_2048_inf vif (
    .clk   (clk),
    .rst_n (rst_n)
  );

  tt_um_2048 dut (
    .ui_in   (vif.ui_in),
    .uo_out  (vif.uo_out),
    .uio_in  (vif.uio_in),
    .uio_out (vif.uio_out),
    .uio_oe  (vif.uio_oe),
    .ena     (vif.ena),
    .clk     (clk),
    .rst_n   (rst_n)
  );

  bind tt_um_2048 game2048_sva_bb u_sva (.*);
  initial begin
    uvm_config_db#(virtual game_2048_inf.DRV)::set(
      null, "*", "vif", vif
    );

    uvm_config_db#(virtual game_2048_inf.MON)::set(
      null, "*", "vif", vif
    );
    uvm_config_db#(virtual game_2048_inf)::set(null, "*", "vif", vif);

    run_test("test");
  end

  // Hard reset
  initial begin
    rst_n = 1'b0;

    repeat (5)
      @(posedge clk);

    @(negedge clk);
    rst_n = 1'b1;
  end

endmodule