`include "defines.svh"
interface game_2048_inf(input logic clk,input logic rst_n);
logic [`input_width-1:0]ui_in;
logic [`input_width-1:0]uio_in;
logic ena;

logic [`output_width-1:0]uo_out;
logic [`output_width-1:0]uio_out;
logic [`output_width-1:0]uio_oe;


clocking drv@(posedge clk);
    output ui_in;
    output uio_in;
    output ena;

    input uo_out;
    input uio_out;
    input uio_oe;
endclocking

clocking mon@(posedge clk);
    input ui_in;
    input uio_in;
    input ena;
    input uo_out;
    input uio_out;
    input uio_oe;
endclocking

modport DRV(clocking drv,input rst_n);
modport MON(clocking mon);
endinterface



