class game2048_subscriber extends uvm_subscriber #(seq_item);
  `uvm_component_utils(game2048_subscriber)

  seq_item item;

  covergroup game2048_cg;
    option.per_instance = 1;

    // 1. Reset & Enable
    rst_n_toggle : coverpoint item.rst_n {
      bins low  = {1'b0};
      bins high = {1'b1};
    }

    ena_toggle : coverpoint item.ena {
      bins high = {1'b1};
    }

    // 2. Individual Button Toggles
    up_toggle : coverpoint item.ui_in[0] {
      bins high = {1'b1};
      bins low  = {1'b0};
    }
    down_toggle : coverpoint item.ui_in[1] {
      bins high = {1'b1};
      bins low  = {1'b0};
    }
    left_toggle : coverpoint item.ui_in[2] {
      bins high = {1'b1};
      bins low  = {1'b0};
    }
    right_toggle : coverpoint item.ui_in[3] {
      bins high = {1'b1};
      bins low  = {1'b0};
    }
    srst_toggle : coverpoint item.ui_in[4] {
      bins high = {1'b1};
      bins low  = {1'b0};
    }

    // 3. Clean Single-Button Presses (1-hot)
    single_btn : coverpoint item.ui_in[4:0] {
      bins up_only    = {5'b00001};
      bins down_only  = {5'b00010};
      bins left_only  = {5'b00100};
      bins right_only = {5'b01000};
      bins srst_only  = {5'b10000};
    }

    // 4. All 10 Two-Button Pairs (Priority Encoder Pairs)
    button_pairs : coverpoint item.ui_in[4:0] {
      bins up_down    = {5'b00011};
      bins up_left    = {5'b00101};
      bins up_right   = {5'b01001};
      bins up_srst    = {5'b10001};
      bins down_left  = {5'b00110};
      bins down_right = {5'b01010};
      bins down_srst  = {5'b10010};
      bins left_right = {5'b01100};
      bins left_srst  = {5'b10100};
      bins right_srst = {5'b11000};
    }

    // 5. 3-, 4-, and 5-Button Simultaneous Combinations & Idle
    button_combination : coverpoint item.ui_in[4:0] {
      bins none          = {5'b00000};
      bins three_buttons = {5'b00111, 5'b01011, 5'b01101, 5'b01110, 5'b10011,
                            5'b10101, 5'b10110, 5'b11001, 5'b11010, 5'b11100};
      bins four_buttons  = {5'b01111, 5'b10111, 5'b11011, 5'b11101, 5'b11110};
      bins all_five      = {5'b11111};
    }

    // 6. Unused Pins Range
    uio_in_range : coverpoint item.uio_in {
      bins low  = {[8'h00:8'h55]};
      bins mid  = {[8'h56:8'hAA]};
      bins high = {[8'hAB:8'hFF]};
    }

    // 7. Cross Coverage: Every Single Button x Unused Pin Ranges (15 bins)
    cx_single_btn_x_uio : cross single_btn, uio_in_range;

    // 8. Cross Coverage: Single Buttons during Active Operation (rst_n == 1)
    //    (Ignores rst_n == 0 bins unless a test explicitly drives buttons during hard reset)
    cx_single_btn_active : cross single_btn, rst_n_toggle {
      ignore_bins during_hard_reset = binsof(rst_n_toggle.low);
    }

    // 9. Cross Coverage: Multi-Button Pairs x Unused Pin Ranges (30 bins)
    cx_pairs_x_uio : cross button_pairs, uio_in_range;

  endgroup

  function new(string name = "game2048_subscriber", uvm_component parent);
    super.new(name, parent);
    game2048_cg = new();
  endfunction

  function void write(seq_item t);
    item = t;
    game2048_cg.sample();
  endfunction
endclass
// class game2048_subscriber extends uvm_subscriber #(seq_item);
//   `uvm_component_utils(game2048_subscriber)
 
//   seq_item item;
 
//   covergroup game2048_cg;
//     option.per_instance = 1;
// /*
//     rst_n_toggle : coverpoint item.Rst_n {
//       bins low  = {0};
//       bins high = {1};
//     }*/
 
//     up_toggle : coverpoint item.ui_in[0] {
//       bins high = {1};
//       bins low  = {0};
//     }
//     down_toggle : coverpoint item.ui_in[1] {
//       bins high = {1};
//       bins low  = {0};
//     }
//     left_toggle : coverpoint item.ui_in[2] {
//       bins high = {1};
//       bins low  = {0};
//     }
//     right_toggle : coverpoint item.ui_in[3] {
//       bins high = {1};
//       bins low  = {0};
//     }
//     srst_toggle : coverpoint item.ui_in[4] {
//       bins high = {1};
//       bins low  = {0};
//     }
 
//     ena_toggle : coverpoint item.ena {
//       bins high = {1};
//     }
 
//     uio_in_range : coverpoint item.uio_in {
//       bins low  = {[8'h00:8'h55]};
//       bins mid  = {[8'h56:8'hAA]};
//       bins high = {[8'hAB:8'hFF]};
//     }
 
//     button_combination : coverpoint item.ui_in[4:0] {
//       bins none          = {5'b00000};
//       bins three_buttons = {5'b00111, 5'b01011, 5'b01101, 5'b01110, 5'b10011,
//                             5'b10101, 5'b10110, 5'b11001, 5'b11010, 5'b11100};
//       bins four_buttons  = {5'b01111, 5'b10111, 5'b11011, 5'b11101, 5'b11110};
//       bins all_five      = {5'b11111};
//     }
 
//     button_pairs : coverpoint item.ui_in[4:0] {
//       bins up_down    = {5'b00011};
//       bins up_left    = {5'b00101};
//       bins up_right   = {5'b01001};
//       bins up_srst    = {5'b10001};
//       bins down_left  = {5'b00110};
//       bins down_right = {5'b01010};
//       bins down_srst  = {5'b10010};
//       bins left_right = {5'b01100};
//       bins left_srst  = {5'b10100};
//       bins right_srst = {5'b11000};
//     }
//   endgroup
 
//   function new(string name = "game2048_subscriber", uvm_component parent);
//     super.new(name, parent);
//     game2048_cg = new();         
//   endfunction
 
//   function void write(seq_item t);
//     item = t;
//     game2048_cg.sample();
//   endfunction
// endclass