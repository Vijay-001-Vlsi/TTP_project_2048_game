
class base_sequence extends uvm_sequence #(seq_item);
  `uvm_object_utils(base_sequence)

  localparam bit [7:0] BTN_NONE  = 8'b0000_0000; // 0x00
  localparam bit [7:0] BTN_UP    = 8'b0000_0001; // 0x01
  localparam bit [7:0] BTN_DOWN  = 8'b0000_0010; // 0x02
  localparam bit [7:0] BTN_LEFT  = 8'b0000_0100; // 0x04
  localparam bit [7:0] BTN_RIGHT = 8'b0000_1000; // 0x08
  localparam bit [7:0] BTN_SRST  = 8'b0001_0000; // 0x10

  function new(string name = "base_sequence");
    super.new(name);
  endfunction

  // Standard button/control press (keeps unused pins tied per constraint c1)
  task send_btn(bit [7:0] val);
    req = seq_item::type_id::create("req");
    start_item(req);
    if (!req.randomize() with {
      ui_in  == val;
      uio_in == 8'h00;
      ena    == 1'b1;
    }) begin
      `uvm_fatal("SEQ", $sformatf("Randomization failed for ui_in=0x%0h", val))
    end
    finish_item(req);
  endtask

  // Raw pin drive (disables constraint c1 to toggle unused ui_in[7:5], uio_in[7:0], ena)
  task send_raw_pins(bit [7:0] ui_val, bit [7:0] uio_val, bit ena_val);
    req = seq_item::type_id::create("req");
    req.c1.constraint_mode(0);
    start_item(req);
    if (!req.randomize() with {
      ui_in  == ui_val;
      uio_in == uio_val;
      ena    == ena_val;
    }) begin
      `uvm_fatal("SEQ", "Raw pin randomization failed")
    end
    finish_item(req);
  endtask

  virtual task body();
    send_btn(BTN_SRST);
    send_btn(BTN_UP);
  endtask
endclass

// =============================================================================
// 1. Smoke & Basic 4-Direction Slide/Merge Sequence (F-001, F-003, F-007, F-008)
// =============================================================================
class game_smoke_seq extends base_sequence;
  `uvm_object_utils(game_smoke_seq)

  function new(string name = "game_smoke_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info("SEQ", "=== [1/11] Starting game_smoke_seq ===", UVM_LOW)
    send_btn(BTN_SRST);
    send_btn(BTN_UP);
    send_btn(BTN_LEFT);
    send_btn(BTN_DOWN);
    send_btn(BTN_RIGHT);
    send_btn(BTN_UP);
    send_btn(BTN_LEFT);
  endtask
endclass

// =============================================================================
// 2. Game-Over Without Soft Reset After Hard Reset (C-023, F-013, C-016, C-017)
//    Must run right after initial hard reset before any s_rst!
// =============================================================================
class game_no_srst_gameover_seq extends base_sequence;
  `uvm_object_utils(game_no_srst_gameover_seq)

  function new(string name = "game_no_srst_gameover_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info("SEQ", "=== [2/11] Starting game_no_srst_gameover_seq (C-023) ===", UVM_LOW)
    // Board is empty after hard reset; all 4 directions fail -> game_over = 4'b1111
    send_btn(BTN_UP);
    send_btn(BTN_DOWN);
    send_btn(BTN_LEFT);
    send_btn(BTN_RIGHT);

    // C-016: Extra moves while lost must remain blocked
    send_btn(BTN_LEFT);
    send_btn(BTN_UP);

    // C-017: Soft reset clears red loss border and starts valid game
    send_btn(BTN_SRST);
    send_btn(BTN_DOWN);
  endtask
endclass

// =============================================================================
// 3. Exhaustive 32-Combination Priority Encoder & Mux Sequence (F-005, C-003)
//    Hits all 32 entries of priority_encoder, mux, and demux in debounce_top.v
// =============================================================================
class game_all_32_prio_seq extends base_sequence;
  `uvm_object_utils(game_all_32_prio_seq)

  function new(string name = "game_all_32_prio_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info("SEQ", "=== [3/11] Starting game_all_32_prio_seq (All 32 Input Masks) ===", UVM_LOW)
    send_btn(BTN_SRST);

    // Sweep all 32 values of ui_in[4:0]: 00000 through 11111
    // Covers:
    //   00000        -> IDLE (sel = 3'd1)
    //   00001        -> UP   (sel = 3'd7)
    //   00010..00011 -> DOWN (sel = 3'd6)
    //   00100..00111 -> LEFT (sel = 3'd5)
    //   01000..01111 -> RIGHT(sel = 3'd4)
    //   10000..11111 -> SRST (sel = 3'd0)
    for (int i = 0; i < 32; i++) begin
      send_btn(8'(i));
    end

    // Confirm normal directional moves work after full priority sweep
    send_btn(BTN_LEFT);
    send_btn(BTN_UP);
    send_btn(BTN_RIGHT);
    send_btn(BTN_DOWN);
  endtask
endclass

// =============================================================================
// 4. Debouncer FSM Transition & Overlap Sequence (F-004, F-006, C-003..C-005)
//    Targets S0->S1, S1->S1, S1->S2, S2->S2, S2->S3, S3->S3, S3->S0
// =============================================================================
class game_glitch_and_overlap_seq extends base_sequence;
  `uvm_object_utils(game_glitch_and_overlap_seq)

  function new(string name = "game_glitch_and_overlap_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info("SEQ", "=== [4/11] Starting game_glitch_and_overlap_seq ===", UVM_LOW)
    send_btn(BTN_SRST);

    // S0 -> S0 idle cycles
    repeat (3) send_btn(BTN_NONE);

    // Repeated identical direction assertions (full S0->S1->S2->S3->S0 cycle)
    send_btn(BTN_RIGHT);
    send_btn(BTN_RIGHT);
    send_btn(BTN_UP);
    send_btn(BTN_UP);

    // Simultaneous multi-button combinations across every priority pair
    send_btn(BTN_UP | BTN_DOWN);
    send_btn(BTN_DOWN | BTN_LEFT);
    send_btn(BTN_LEFT | BTN_RIGHT);
    send_btn(BTN_UP | BTN_DOWN | BTN_LEFT | BTN_RIGHT);
    send_btn(BTN_RIGHT | BTN_SRST);
    send_btn(BTN_UP | BTN_SRST);

    // Resume normal play
    send_btn(BTN_LEFT);
    send_btn(BTN_DOWN);
  endtask
endclass

// =============================================================================
// 5. Grid Traversal, Compression & Single-Merge-Limit Sequence
//    Hits all FINDZ, FINDCOMPANION (2'b00/01/10/11), UPDATENOW, GATECHECK branches
// =============================================================================
class game_merge_rules_seq extends base_sequence;
  `uvm_object_utils(game_merge_rules_seq)

  function new(string name = "game_merge_rules_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info("SEQ", "=== [5/11] Starting game_merge_rules_seq ===", UVM_LOW)
    send_btn(BTN_SRST);

    // Alternate horizontal & vertical compression + merges in all 4 directions
    // Exercises:
    // - FINDZ 2'b00 (non-zero mid-line), 2'b01 (non-zero at end), 2'b10 (zero step), 2'b11 (all zeros)
    // - FINDCOMPANION 2'b01 (equal merge), 2'b00 (non-equal block), 2'b10 (zero at trav), 2'b11 (both zero)
    // - GATECHECK now==trav vs now!=trav
    repeat (10) begin
      send_btn(BTN_LEFT);
      send_btn(BTN_LEFT);
      send_btn(BTN_UP);
      send_btn(BTN_UP);
      send_btn(BTN_RIGHT);
      send_btn(BTN_DOWN);
    end
  endtask
endclass

// =============================================================================
// 6. Invalid Move, Direction-Flag Clear (C-013, C-014) & Mid-Game Soft Reset (C-002)
// =============================================================================
class game_invalid_and_reset_seq extends base_sequence;
  `uvm_object_utils(game_invalid_and_reset_seq)

  function new(string name = "game_invalid_and_reset_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info("SEQ", "=== [6/11] Starting game_invalid_and_reset_seq ===", UVM_LOW)
    send_btn(BTN_SRST);

    // C-013: Push tiles to top-left corner, then repeat invalid moves in same direction
    repeat (4) send_btn(BTN_UP);
    repeat (4) send_btn(BTN_LEFT);

    // C-014: Single valid move (DOWN) clears all accumulated game_over[3:0] flags
    send_btn(BTN_DOWN);

    // Repeat UP and LEFT lock to prove flags were cleared (must NOT trigger loss)
    repeat (4) send_btn(BTN_UP);
    repeat (4) send_btn(BTN_LEFT);

    // C-002: Mid-game soft reset wipes board and inserts 1 fresh tile
    send_btn(BTN_SRST);
    send_btn(BTN_RIGHT);
    send_btn(BTN_DOWN);

    // Second consecutive soft reset while active
    send_btn(BTN_SRST);
    send_btn(BTN_LEFT);
  endtask
endclass

// =============================================================================
// 7. Occupied-Cell LFSR Retry Stress Sequence (F-010, F-011, C-006)
//    Forces RANDINS -> RANDINS self-loop when rand_pos points to occupied cells
// =============================================================================
class game_occupied_retry_seq extends base_sequence;
  `uvm_object_utils(game_occupied_retry_seq)

  function new(string name = "game_occupied_retry_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info("SEQ", "=== [7/11] Starting game_occupied_retry_seq (C-006) ===", UVM_LOW)
    send_btn(BTN_SRST);

    // Pack the 4x4 grid densely so 12-15 cells are occupied, forcing
    // RANDINS (comp2_out == 0) to reject occupied LFSR positions and retry
    repeat (10) begin
      send_btn(BTN_UP);
      send_btn(BTN_LEFT);
      send_btn(BTN_DOWN);
      send_btn(BTN_RIGHT);
    end
  endtask
endclass

// =============================================================================
// 8. Unused & Reserved Pins Isolation + Toggle Sequence (Spec Section 4.3)
//    Toggles all bits of ui_in[7:5], uio_in[7:0] (0x00/0xFF/0xAA/0x55), and ena (0/1)
// =============================================================================
class game_unused_pins_seq extends base_sequence;
  `uvm_object_utils(game_unused_pins_seq)

  function new(string name = "game_unused_pins_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info("SEQ", "=== [8/11] Starting game_unused_pins_seq (Spec 4.3) ===", UVM_LOW)
    // Soft reset with unused upper bits ui_in[7:5]=3'b101, uio_in=8'hAA, ena=0
    send_raw_pins(8'b1011_0000, 8'hAA, 1'b0);

    // Directional moves toggling every unused pin from 0->1 and 1->0
    send_raw_pins(8'b1110_0001, 8'h55, 1'b0); // UP
    send_raw_pins(8'b0100_0100, 8'hFF, 1'b1); // LEFT
    send_raw_pins(8'b1000_0010, 8'h00, 1'b0); // DOWN
    send_raw_pins(8'b0010_1000, 8'hF0, 1'b1); // RIGHT
    send_raw_pins(8'b1100_0001, 8'h0F, 1'b0); // UP
  endtask
endclass

// =============================================================================
// 9. Full Board Game-Over & Recovery Sequence (F-013, C-012, C-016, C-017)
// =============================================================================
class game_over_seq extends base_sequence;
  `uvm_object_utils(game_over_seq)

  function new(string name = "game_over_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info("SEQ", "=== [9/11] Starting game_over_seq (C-012, C-016, C-017) ===", UVM_LOW)
    send_btn(BTN_SRST);

    // Saturate board and lock all 4 directions (game_over == 4'b1111 -> red border)
    repeat (14) begin
      send_btn(BTN_UP);
      send_btn(BTN_LEFT);
      send_btn(BTN_DOWN);
      send_btn(BTN_RIGHT);
    end

    // C-016: Verify all 4 directions are rejected after game_over is asserted
    send_btn(BTN_UP);
    send_btn(BTN_DOWN);
    send_btn(BTN_LEFT);
    send_btn(BTN_RIGHT);

    // C-017: Verify soft reset clears loss state and restarts game
    send_btn(BTN_SRST);
    send_btn(BTN_RIGHT);
    send_btn(BTN_UP);
  endtask
endclass

// =============================================================================
// 10. Hybrid Backdoor All-Glyph (2..2048) & 2048 Win Sequence
//     (F-012, F-015, F-016, C-011, C-015, C-017)
// =============================================================================
typedef class scoreboard;
class game_win_glyph_seq extends base_sequence;
  `uvm_object_utils(game_win_glyph_seq)

  int unsigned               num_cycles = 1;
  scoreboard                 scb_h;
  virtual game_2048_inf      vif;

  function new(string name = "game_win_glyph_seq");
    super.new(name);
  endfunction

  task body();
    int preload [4][4];
    `uvm_info("SEQ", "=== [10/11] Starting Hybrid Backdoor game_win_glyph_seq ===", UVM_LOW)

    if (vif == null && !uvm_config_db#(virtual game_2048_inf)::get(null, "*", "vif", vif))
      `uvm_fatal("SEQ", "Virtual interface vif not found for backdoor preload")

    // 1. Front-door soft reset so debouncer and FSM are cleanly initialized
    send_btn(BTN_SRST);

    // 2. Prepare board containing EVERY tile value (2..1024) + two 1024s in row 0
    preload = '{
      '{10, 10,  9,  8},
      '{ 7,  6,  5,  4},
      '{ 3,  2,  1,  0},
      '{ 0,  0,  0,  0}
    };

    // 3. Backdoor write via interface task and sync scoreboard on the same edge
    vif.backdoor_load_grid(preload);
    if (scb_h != null) scb_h.backdoor_sync_grid(preload);

    // 4. Front-door LEFT move -> merges 1024 + 1024 = 2048, triggers gamewon_vga = 1
    send_btn(BTN_LEFT);

    // 5. C-015: Verify all 4 directions are blocked after win
    send_btn(BTN_UP);
    send_btn(BTN_DOWN);
    send_btn(BTN_LEFT);
    send_btn(BTN_RIGHT);

    // 6. C-017: Verify soft reset clears green win border and restarts normal play
    send_btn(BTN_SRST);
    send_btn(BTN_UP);
  endtask
endclass

// =============================================================================
// 11. Constrained-Random Gameplay Sequence (Closes Cross-Coverage & Toggle Holes)
// =============================================================================
class game_random_seq extends base_sequence;
  `uvm_object_utils(game_random_seq)

  rand int unsigned num_moves;
  constraint c_num_moves { num_moves inside {[45:65]}; }

  function new(string name = "game_random_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info("SEQ", $sformatf("=== [11/11] Starting game_random_seq (%0d random ops) ===", num_moves), UVM_LOW)
    send_btn(BTN_SRST);

    repeat (num_moves) begin
      req = seq_item::type_id::create("req");
      start_item(req);
      if (!req.randomize() with {
        ui_in[4:0] dist {
          5'b00001 := 21, // UP
          5'b00010 := 21, // DOWN
          5'b00100 := 21, // LEFT
          5'b01000 := 21, // RIGHT
          5'b00000 := 5,  // IDLE
          5'b00011 := 2,  // Multi-button DOWN > UP
          5'b00110 := 2,  // Multi-button LEFT > DOWN
          5'b01100 := 2,  // Multi-button RIGHT > LEFT
          5'b10000 := 3   // Occasional mid-run soft reset
        };
        uio_in == 8'h00;
        ena    == 1'b1;
      }) begin
        `uvm_fatal("SEQ", "Random move generation failed")
      end
      finish_item(req);
    end
  endtask
endclass

// =============================================================================
// Master Regression Sequence (Runs All 11 Sequences Back-to-Back)
// =============================================================================
class full_regression_seq extends base_sequence;
  `uvm_object_utils(full_regression_seq)

  function new(string name = "full_regression_seq");
    super.new(name);
  endfunction

  task body();
    game_no_srst_gameover_seq no_srst_s;
    game_smoke_seq            smoke_s;
    game_all_32_prio_seq      prio32_s;
    game_glitch_and_overlap_seq glitch_s;
    game_merge_rules_seq      merge_s;
    game_invalid_and_reset_seq inv_rst_s;
    game_occupied_retry_seq   occ_s;
    game_unused_pins_seq      unused_s;
    game_over_seq             over_s;
    game_win_glyph_seq        win_s;
    game_random_seq           rand_s;

    `uvm_info("REG_SEQ", "==================================================", UVM_LOW)
    `uvm_info("REG_SEQ", " STARTING FULL 2048 SPEC v1.7 REGRESSION SUITE", UVM_LOW)
    `uvm_info("REG_SEQ", "==================================================", UVM_LOW)

    // 1. Must run first right after hard reset to verify C-023!
    no_srst_s = game_no_srst_gameover_seq::type_id::create("no_srst_s");
    no_srst_s.start(m_sequencer);

    // 2. Basic smoke
    smoke_s = game_smoke_seq::type_id::create("smoke_s");
    smoke_s.start(m_sequencer);

    // 3. Exhaustive 32-entry priority encoder
    prio32_s = game_all_32_prio_seq::type_id::create("prio32_s");
    prio32_s.start(m_sequencer);

    // 4. Idle, repeat-hold, and overlapping priority transitions
    glitch_s = game_glitch_and_overlap_seq::type_id::create("glitch_s");
    glitch_s.start(m_sequencer);

    // 5. Merge rules, single-merge limit, and boundary traversal
    merge_s = game_merge_rules_seq::type_id::create("merge_s");
    merge_s.start(m_sequencer);

    // 6. Invalid move flags, flag clear on move, and mid-game soft reset
    inv_rst_s = game_invalid_and_reset_seq::type_id::create("inv_rst_s");
    inv_rst_s.start(m_sequencer);

    // 7. Occupied-cell LFSR retry stress
    occ_s = game_occupied_retry_seq::type_id::create("occ_s");
    occ_s.start(m_sequencer);

    // 8. Unused pins isolation
    unused_s = game_unused_pins_seq::type_id::create("unused_s");
    unused_s.start(m_sequencer);

    // 9. Game-over saturation & soft-reset recovery
    over_s = game_over_seq::type_id::create("over_s");
    over_s.start(m_sequencer);

  // 10. High-tile glyph & win sequence (hybrid backdoor preload + front-door 2048 merge)
    win_s = game_win_glyph_seq::type_id::create("win_s");
    $cast(win_s.scb_h, uvm_top.find("uvm_test_top.envh.scrh"));
    win_s.start(m_sequencer);

    // 11. Constrained-random gameplay
    rand_s = game_random_seq::type_id::create("rand_s");
    if (!rand_s.randomize()) `uvm_fatal("REG_SEQ", "Randomization of game_random_seq failed")
    rand_s.start(m_sequencer);

    `uvm_info("REG_SEQ", "==================================================", UVM_LOW)
    `uvm_info("REG_SEQ", " COMPLETED FULL 2048 SPEC v1.7 REGRESSION SUITE", UVM_LOW)
    `uvm_info("REG_SEQ", "==================================================", UVM_LOW)
  endtask
endclass