`include "defines.svh"
interface game_2048_inf(input logic clk,input logic rst_n);
logic [`input_width-1:0]ui_in;
logic [`input_width-1:0]uio_in;
logic ena;

logic [`output_width-1:0]uo_out;
logic [`output_width-1:0]uio_out;
logic [`output_width-1:0]uio_oe;


clocking drv@(posedge clk);
default input #1step output #0;
    output ui_in;
    output uio_in;
    output ena;

    input uo_out;
    input uio_out;
    input uio_oe;
endclocking

clocking mon@(posedge clk);
default input #1step;
    input ui_in;
    input uio_in;
    input ena;
    input uo_out;
    input uio_out;
    input uio_oe;
    input rst_n;
endclocking

modport DRV(clocking drv,input rst_n);
modport MON(clocking mon);
task automatic backdoor_load_grid(input int preload [4][4]);
    @(posedge clk);
    for (int r = 0; r < 4; r++) begin
      for (int c = 0; c < 4; c++) begin
        tb_top.dut.u_grid_core.grid[r][c] = 4'(preload[r][c]);
      end
    end
  endtask
endinterface



