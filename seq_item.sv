class seq_item extends uvm_sequence_item;
    `uvm_object_utils(seq_item)
rand bit [`input_width-1:0]ui_in;
rand bit [`input_width-1:0]uio_in;
rand bit ena;

bit [`output_width-1:0]uo_out;
bit [`output_width-1:0]uio_out;
bit [`output_width-1:0]uio_oe;

function new(string name="seq_item");
    super.new(name);
endfunction
constraint c1{uio_in==8'b0;ena==1'b1;}


endclass

