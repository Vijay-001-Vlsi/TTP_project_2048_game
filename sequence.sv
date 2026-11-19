// class base_sequence extends uvm_sequence#(seq_item);
//     `uvm_object_utils(base_sequence)

//     function new(string name="base_sequence");
//         super.new(name);
//     endfunction

//     task body();
//         req=seq_item::type_id::create("req");
//         start_item(req);
//         assert(req.randomize() with {ui_in==8'b00010000;})
//         finish_item(req);
//         req=seq_item::type_id::create("req");
//         start_item(req);
//         assert(req.randomize() with {ui_in==8'b00000001;})
//         finish_item(req);
//     endtask
// endclass

// =============================================================================
// Base Sequence with Reusable Helper Tasks for tt_um_2048
// Pin Mapping (tt_um_2048.v): ui_in[4:0] = {s_rst, right, left, down, up}
// =============================================================================
class base_sequence extends uvm_sequence #(seq_item);
    `uvm_object_utils(base_sequence)

    localparam bit [7:0] BTN_UP    = 8'b0000_0001; // 0x01
    localparam bit [7:0] BTN_DOWN  = 8'b0000_0010; // 0x02
    localparam bit [7:0] BTN_LEFT  = 8'b0000_0100; // 0x04
    localparam bit [7:0] BTN_RIGHT = 8'b0000_1000; // 0x08
    localparam bit [7:0] BTN_SRST  = 8'b0001_0000; // 0x10

    function new(string name = "base_sequence");
        super.new(name);
    endfunction

    // Helper: Send a single button/control press
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

    // Default basic smoke sequence (s_rst + single UP move)
    virtual task body();
        send_btn(BTN_SRST);
        send_btn(BTN_UP);
    endtask
endclass

// =============================================================================
// 1. Smoke & Basic Slide/Merge Sequence
//    Verifies soft reset initialization, 4-direction sliding, and basic merging
// =============================================================================
class game_smoke_seq extends base_sequence;
    `uvm_object_utils(game_smoke_seq)

    function new(string name = "game_smoke_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info("SEQ", "=== Starting game_smoke_seq ===", UVM_LOW)
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
// 2. Priority Encoder & Simultaneous Multi-Button Corner Sequence
//    Tests priority_encoder.v precedence: s_rst > right > left > down > up
//    and unused upper bits ui_in[7:5]
// =============================================================================
class game_moves_prio_seq extends base_sequence;
    `uvm_object_utils(game_moves_prio_seq)

    function new(string name = "game_moves_prio_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info("SEQ", "=== Starting game_moves_prio_seq (Priority & Corner Inputs) ===", UVM_LOW)
        send_btn(BTN_SRST);

        // 1. Upper unused bits set (ui_in[7:5] = 3'b111) + UP -> must behave identically to UP
        send_btn(8'b1110_0001);

        // 2. Simultaneous UP + DOWN -> DOWN must win (prio: down > up)
        send_btn(BTN_UP | BTN_DOWN);

        // 3. Simultaneous UP + DOWN + LEFT -> LEFT must win (prio: left > down > up)
        send_btn(BTN_UP | BTN_DOWN | BTN_LEFT);

        // 4. Simultaneous RIGHT + LEFT + DOWN + UP -> RIGHT must win (prio: right > left)
        send_btn(BTN_RIGHT | BTN_LEFT | BTN_DOWN | BTN_UP);

        // 5. Simultaneous s_rst + all 4 directions -> s_rst must win and clear grid
        send_btn(BTN_SRST | BTN_RIGHT | BTN_LEFT | BTN_DOWN | BTN_UP);

        // 6. Follow-up valid move after priority soft reset
        send_btn(BTN_DOWN);
    endtask
endclass

// =============================================================================
// 3. Invalid Move & Mid-Game Soft Reset Corner Sequence
//    - Presses the SAME direction repeatedly until tiles hit the wall and can
//      no longer move (verifies RTL does NOT spawn a tile on an invalid move).
//    - Triggers mid-game soft reset and verifies clean board restart.
// =============================================================================
class game_invalid_and_reset_seq extends base_sequence;
    `uvm_object_utils(game_invalid_and_reset_seq)

    function new(string name = "game_invalid_and_reset_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info("SEQ", "=== Starting game_invalid_and_reset_seq ===", UVM_LOW)
        send_btn(BTN_SRST);

        // Press UP 4 times in a row: after tile reaches Row 0, subsequent UPs are invalid moves
        repeat (4) send_btn(BTN_UP);

        // Press LEFT 4 times in a row: pushes tiles into [0][0] corner, then tests invalid LEFTs
        repeat (4) send_btn(BTN_LEFT);

        // Mid-game soft reset: must wipe all accumulated tiles and spawn 1 fresh tile
        send_btn(BTN_SRST);

        // Verify game continues normally after mid-game reset
        send_btn(BTN_RIGHT);
        send_btn(BTN_DOWN);
    endtask
endclass

// =============================================================================
// 4. Constrained-Random Gameplay Sequence
//    Exercises randomized 1-hot directional moves + occasional soft resets
// =============================================================================
class game_random_seq extends base_sequence;
    `uvm_object_utils(game_random_seq)

    rand int unsigned num_moves;
    constraint c_num_moves { num_moves inside {[15:25]}; }

    function new(string name = "game_random_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info("SEQ", $sformatf("=== Starting game_random_seq (%0d random moves) ===", num_moves), UVM_LOW)
        send_btn(BTN_SRST);

        repeat (num_moves) begin
            req = seq_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                // Weighted 1-hot directional buttons (UP, DOWN, LEFT, RIGHT)
                ui_in inside {8'h01, 8'h02, 8'h04, 8'h08};
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
// 5. Game-Over Corner Sequence
//    Alternates UP/LEFT/DOWN/RIGHT aggressively to fill the 4x4 grid and trigger
//    game_over == 4'b1111 (gamelost_vga = 1 -> red screen border)
// =============================================================================
class game_over_seq extends base_sequence;
    `uvm_object_utils(game_over_seq)

    function new(string name = "game_over_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info("SEQ", "=== Starting game_over_seq ===", UVM_LOW)
        send_btn(BTN_SRST);

        // Cycle through all 4 directions for 45 moves to saturate the 16-cell board
        repeat (11) begin
            send_btn(BTN_UP);
            send_btn(BTN_LEFT);
            send_btn(BTN_DOWN);
            send_btn(BTN_RIGHT);
        end

        // Extra move after full board to verify locked state and red lost border
        send_btn(BTN_UP);
    endtask
endclass

// =============================================================================
// 6. Win & High-Tile Glyph Sequence (2048 Win Condition)
//    Uses corner-building strategy (UP + LEFT alternating with recovery moves)
//    to merge up to high tile values and test win state / glyph rendering
// =============================================================================
class game_win_glyph_seq extends base_sequence;
    `uvm_object_utils(game_win_glyph_seq)

    function new(string name = "game_win_glyph_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info("SEQ", "=== Starting game_win_glyph_seq ===", UVM_LOW)
        send_btn(BTN_SRST);

        // Corner-building pattern (favoring UP and LEFT to chain merges)
        repeat (15) begin
            send_btn(BTN_UP);
            send_btn(BTN_LEFT);
            send_btn(BTN_UP);
            send_btn(BTN_RIGHT);
        end
    endtask
endclass

// =============================================================================
// 7. Master Regression Sequence (Runs All Sequences Back-to-Back)
// =============================================================================
class full_regression_seq extends base_sequence;
    `uvm_object_utils(full_regression_seq)

    function new(string name = "full_regression_seq");
        super.new(name);
    endfunction

    task body();
        game_smoke_seq             smoke_s;
        game_moves_prio_seq        prio_s;
        game_invalid_and_reset_seq inv_rst_s;
        game_random_seq            rand_s;
        game_over_seq              over_s;
        game_win_glyph_seq         win_s;

        `uvm_info("REG_SEQ", "==================================================", UVM_LOW)
        `uvm_info("REG_SEQ", " STARTING FULL 2048 REGRESSION SUITE", UVM_LOW)
        `uvm_info("REG_SEQ", "==================================================", UVM_LOW)

        smoke_s = game_smoke_seq::type_id::create("smoke_s");
        smoke_s.start(m_sequencer);

        prio_s = game_moves_prio_seq::type_id::create("prio_s");
        prio_s.start(m_sequencer);

        inv_rst_s = game_invalid_and_reset_seq::type_id::create("inv_rst_s");
        inv_rst_s.start(m_sequencer);

        rand_s = game_random_seq::type_id::create("rand_s");
        assert(rand_s.randomize());
        rand_s.start(m_sequencer);

        over_s = game_over_seq::type_id::create("over_s");
        over_s.start(m_sequencer);

        win_s = game_win_glyph_seq::type_id::create("win_s");
        win_s.start(m_sequencer);

        `uvm_info("REG_SEQ", "==================================================", UVM_LOW)
        `uvm_info("REG_SEQ", " COMPLETED FULL 2048 REGRESSION SUITE", UVM_LOW)
        `uvm_info("REG_SEQ", "==================================================", UVM_LOW)
    endtask
endclass