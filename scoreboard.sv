class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)

  uvm_tlm_analysis_fifo #(seq_item) fifo_in;
  uvm_tlm_analysis_fifo #(seq_item) fifo_op;

  localparam int H_ACTIVE     = 640;
  localparam int H_TOTAL      = 800;
  localparam int V_ACTIVE     = 480;
  localparam int V_FP         = 10;
  localparam int V_TOTAL      = 525;

  localparam int GRID_N       = 4;
  localparam int CELL_SIZE    = 64;
  localparam int BOARD_SIZE   = 256;
  localparam int BOARD_X0     = 192;
  localparam int BOARD_Y0     = 112;

  localparam int EXP_EMPTY    = 0;
  localparam int EXP_WIN      = 11;                 

  localparam int CMD_NONE     = 0;
  localparam int CMD_UP       = 1;
  localparam int CMD_DOWN     = 2;
  localparam int CMD_LEFT     = 3;
  localparam int CMD_RIGHT    = 4;
  localparam int CMD_SRST     = 5;

  localparam int DIR_UP       = 0;
  localparam int DIR_DOWN     = 1;
  localparam int DIR_LEFT     = 2;
  localparam int DIR_RIGHT    = 3;

  localparam bit [5:0] RGB_BLACK    = 6'b00_00_00;
  localparam bit [5:0] RGB_WHITE    = 6'b11_11_11;
  localparam bit [5:0] RGB_WIN_BG   = 6'b00_10_01;
  localparam bit [5:0] RGB_LOSS_BG  = 6'b11_00_00;
  localparam bit [5:0] RGB_EMPTY_BG = 6'b01_01_01;

  localparam int SYNC_LAG     = 1;
  localparam int VSYNC_FALL_X = SYNC_LAG;
  localparam int VSYNC_FALL_Y = V_ACTIVE + V_FP;

  localparam int SPAWN_WAIT_FALLS = 2;

  bit [5:0]  tile_rgb [12];
  bit [15:0] glyph    [12][16];

  int        model_grid [GRID_N][GRID_N];  
  bit        game_won;
  bit        game_over;                   
  bit [3:0]  dir_fail_flags;               
  bit        awaiting_spawn;
  int        spawn_wait;
  bit        in_hard_reset;

  logic [4:0] btn_sync1;
  logic [4:0] btn_sync2;
  int         cand_cmd;
  int         press_cnt;
  bit         btn_held;
  int         held_cmd;
  int         release_cnt;

  bit        locked;
  bit        prev_vsync;
  int        pix_x;
  int        pix_y;

  int        empty_dot_lo;                 
  int        max_px_msgs_per_frame;
  int        max_px_msgs_total;
  int        max_frame_msgs;

  int unsigned complete_frames;
  int unsigned hard_resets, soft_resets, total_moves, valid_moves, invalid_moves, blocked_moves;
  int unsigned wins_seen, losses_seen;
  int unsigned spawn_2_cnt, spawn_4_cnt;
  int unsigned spawn_pos [GRID_N][GRID_N];
  int unsigned cell_errors, unknown_colour_errors;
  int unsigned frame_bad_px, frame_msgs_printed, total_msgs_printed, bad_frames;
  longint unsigned total_pixels, matched_pixels, mismatched_pixels;

  function new(string name = "scoreboard", uvm_component parent = null);
    super.new(name, parent);
    fifo_in = new("fifo_in", this);
    fifo_op = new("fifo_op", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(int)::get(this, "", "empty_dot_lo", empty_dot_lo))
      empty_dot_lo = 30;
    max_px_msgs_per_frame = 3;
    max_px_msgs_total     = 60;
    max_frame_msgs        = 20;

    init_spec_tables();
    hard_reset();

    complete_frames = 0;
    hard_resets = 0; soft_resets = 0;
    total_moves = 0; valid_moves = 0; invalid_moves = 0; blocked_moves = 0;
    wins_seen = 0; losses_seen = 0; spawn_2_cnt = 0; spawn_4_cnt = 0;
    for (int r = 0; r < GRID_N; r++)
      for (int c = 0; c < GRID_N; c++)
        spawn_pos[r][c] = 0;
    cell_errors = 0; unknown_colour_errors = 0;
    frame_bad_px = 0; frame_msgs_printed = 0; total_msgs_printed = 0; bad_frames = 0;
    total_pixels = 0; matched_pixels = 0; mismatched_pixels = 0;

    `uvm_info("SCB_CFG", $sformatf("BUILD_V4_SIMPLE empty_dot_lo=%0d", empty_dot_lo), UVM_LOW)
  endfunction

  function void init_spec_tables();
    tile_rgb[0]  = RGB_EMPTY_BG;
    tile_rgb[1]  = 6'b11_01_01;   // 2
    tile_rgb[2]  = 6'b11_10_01;   // 4
    tile_rgb[3]  = 6'b11_11_01;   // 8
    tile_rgb[4]  = 6'b00_11_11;   // 16
    tile_rgb[5]  = 6'b00_10_11;   // 32
    tile_rgb[6]  = 6'b00_11_10;   // 64
    tile_rgb[7]  = 6'b00_11_01;   // 128
    tile_rgb[8]  = 6'b11_01_00;   // 256
    tile_rgb[9]  = 6'b11_01_10;   // 512
    tile_rgb[10] = 6'b10_01_11;   // 1024
    tile_rgb[11] = 6'b11_00_01;   // 2048

    for (int e = 0; e < 12; e++)
      for (int r = 0; r < 16; r++)
        glyph[e][r] = 16'h0000;

    glyph[1] = '{ // "2"
      16'b0000000000000000, 16'b0000000000000000, 16'b0000111111110000, 16'b0000111111110000,
      16'b0000000000110000, 16'b0000000000110000, 16'b0000000000110000, 16'b0000111111110000,
      16'b0000111111110000, 16'b0000110000000000, 16'b0000110000000000, 16'b0000110000000000,
      16'b0000111111110000, 16'b0000111111110000, 16'b0000000000000000, 16'b0000000000000000 };

    glyph[2] = '{ // "4"
      16'b0000000000000000, 16'b0000000000000000, 16'b0000110000110000, 16'b0000110000110000,
      16'b0000110000110000, 16'b0000110000110000, 16'b0000110000110000, 16'b0000111111110000,
      16'b0000111111110000, 16'b0000000000110000, 16'b0000000000110000, 16'b0000000000110000,
      16'b0000000000110000, 16'b0000000000110000, 16'b0000000000000000, 16'b0000000000000000 };

    glyph[3] = '{ // "8"
      16'b0000000000000000, 16'b0000000000000000, 16'b0000111111110000, 16'b0000111111110000,
      16'b0000110000110000, 16'b0000110000110000, 16'b0000110000110000, 16'b0000111111110000,
      16'b0000111111110000, 16'b0000110000110000, 16'b0000110000110000, 16'b0000110000110000,
      16'b0000111111110000, 16'b0000111111110000, 16'b0000000000000000, 16'b0000000000000000 };

    glyph[4] = '{ // "16"
      16'b0000000000000000, 16'b0000000000000000, 16'b0001100111111000, 16'b0111100111111000,
      16'b0111100110000000, 16'b0001100110000000, 16'b0001100110000000, 16'b0001100111111100,
      16'b0001100111111100, 16'b0001100110001100, 16'b0001100110001100, 16'b0001100110001100,
      16'b0001100111111100, 16'b0001100111111100, 16'b0000000000000000, 16'b0000000000000000 };

    glyph[5] = '{ // "32"
      16'b0000000000000000, 16'b0000000000000000, 16'b0111111001111110, 16'b0111111001111110,
      16'b0000011000000110, 16'b0000011000000110, 16'b0000011000000110, 16'b0111111001111110,
      16'b0111111001111110, 16'b0000011001100000, 16'b0000011001100000, 16'b0000011001100000,
      16'b0111111001111110, 16'b0111111001111110, 16'b0000000000000000, 16'b0000000000000000 };

    glyph[6] = '{ // "64"
      16'b0000000000000000, 16'b0000000000000000, 16'b1111110001100011, 16'b1111110001100011,
      16'b1100000001100011, 16'b1100000001100011, 16'b1100000001100011, 16'b1111111001111111,
      16'b1111111001111111, 16'b1100011000000011, 16'b1100011000000011, 16'b1100011000000011,
      16'b1111111000000011, 16'b1111111000000011, 16'b0000000000000000, 16'b0000000000000000 };

    glyph[7] = '{ // "128"
      16'b0000000000000000, 16'b0000000000000000, 16'b0000101110111000, 16'b0001101110111000,
      16'b0001100010101000, 16'b0000100010101000, 16'b0000100010101000, 16'b0000101110111000,
      16'b0000101110111000, 16'b0000101000101000, 16'b0000101000101000, 16'b0000101000101000,
      16'b0000101110111000, 16'b0000101110111000, 16'b0000000000000000, 16'b0000000000000000 };

    glyph[8] = '{ // "256"
      16'b0000000000000000, 16'b0000000000000000, 16'b0001110111011100, 16'b0001110111011100,
      16'b0000010100010000, 16'b0000010100010000, 16'b0000010100010000, 16'b0001110111011100,
      16'b0001110111011100, 16'b0001000001010100, 16'b0001000001010100, 16'b0001000001010100,
      16'b0001110111011100, 16'b0001110111011100, 16'b0000000000000000, 16'b0000000000000000 };

    glyph[9] = '{ // "512"
      16'b0000000000000000, 16'b0000000000000000, 16'b0001110010111000, 16'b0001110110111000,
      16'b0001000110001000, 16'b0001000010001000, 16'b0001000010001000, 16'b0001110010111000,
      16'b0001110010111000, 16'b0000010010100000, 16'b0000010010100000, 16'b0000010010100000,
      16'b0001110010111000, 16'b0001110010111000, 16'b0000000000000000, 16'b0000000000000000 };

    glyph[10] = '{ // "1024"
      16'b0000000000000000, 16'b0000000000000000, 16'b0010111011101010, 16'b0110111011101010,
      16'b0110101000101010, 16'b0010101000101010, 16'b0010101000101010, 16'b0010101011101110,
      16'b0010101011101110, 16'b0010101010000010, 16'b0010101010000010, 16'b0010101010000010,
      16'b0010111011100010, 16'b0010111011100010, 16'b0000000000000000, 16'b0000000000000000 };

    glyph[11] = '{ // "2048"
      16'b0000000000000000, 16'b0000000000000000, 16'b0111011101010111, 16'b0111011101010111,
      16'b0001010101010101, 16'b0001010101010101, 16'b0001010101010101, 16'b0111010101110111,
      16'b0111010101110111, 16'b0100010100010101, 16'b0100010100010101, 16'b0100010100010101,
      16'b0111011100010111, 16'b0111011100010111, 16'b0000000000000000, 16'b0000000000000000 };
  endfunction

  function void soft_reset_model();
    for (int r = 0; r < GRID_N; r++)
      for (int c = 0; c < GRID_N; c++)
        model_grid[r][c] = EXP_EMPTY;
    game_won       = 1'b0;
    game_over      = 1'b0;
    dir_fail_flags = 4'b0000;
    awaiting_spawn = 1'b1;
    spawn_wait     = 0;
  endfunction

  function void hard_reset();
    soft_reset_model();
    awaiting_spawn = 1'b0;           
    in_hard_reset  = 1'b0;
    btn_sync1      = 5'd0;
    btn_sync2      = 5'd0;
    cand_cmd       = CMD_NONE;
    press_cnt      = 0;
    btn_held       = 1'b0;
    held_cmd       = CMD_NONE;
    release_cnt    = 0;
    locked         = 1'b0;
    prev_vsync     = 1'b0;
    pix_x          = 0;
    pix_y          = 0;
  endfunction

  function int pick_cmd(logic [4:0] b);
    if (b[4]) return CMD_SRST;
    if (b[3]) return CMD_RIGHT;
    if (b[2]) return CMD_LEFT;
    if (b[1]) return CMD_DOWN;
    if (b[0]) return CMD_UP;
    return CMD_NONE;
  endfunction

  function int tile_val(int e);
    if (e <= 0) return 0;
    return (1 << e);
  endfunction

  function string rgb_str(logic [5:0] v);
    return $sformatf("%02b_%02b_%02b", v[5:4], v[3:2], v[1:0]);
  endfunction

  function int exp_of_rgb(logic [5:0] v);
    for (int e = 0; e < 12; e++)
      if (v === tile_rgb[e]) return e;
    return -1;
  endfunction

  function void cell_of(int dir, int i, int j, output int r, output int c);
    if (dir == DIR_UP)        begin r = j;     c = i;     end
    else if (dir == DIR_DOWN) begin r = 3 - j; c = i;     end
    else if (dir == DIR_LEFT) begin r = i;     c = j;     end
    else                      begin r = i;     c = 3 - j; end
  endfunction
  function bit apply_move(int dir, output bit made_2048);
    int tiles [4];
    int outl  [4];
    int n, k, idx, r, c;
    bit changed;

    changed   = 1'b0;
    made_2048 = 1'b0;

    for (int i = 0; i < GRID_N; i++) begin
      n = 0;
      for (int j = 0; j < GRID_N; j++) begin
        tiles[j] = 0;
        outl[j]  = 0;
      end
      for (int j = 0; j < GRID_N; j++) begin
        cell_of(dir, i, j, r, c);
        if (model_grid[r][c] != EXP_EMPTY) begin
          tiles[n] = model_grid[r][c];
          n++;
        end
      end

      k   = 0;
      idx = 0;
      while (idx < n) begin
        if (idx + 1 < n && tiles[idx] == tiles[idx + 1]) begin
          outl[k] = tiles[idx] + 1;
          if (outl[k] == EXP_WIN) made_2048 = 1'b1;
          idx += 2;
        end
        else begin
          outl[k] = tiles[idx];
          idx += 1;
        end
        k++;
      end

      for (int j = 0; j < GRID_N; j++) begin
        cell_of(dir, i, j, r, c);
        if (model_grid[r][c] != outl[j]) changed = 1'b1;
        model_grid[r][c] = outl[j];
      end
    end
    return changed;
  endfunction

  function void execute_cmd(int cmd);
    bit moved, got_2048;
    int dir;

    if (cmd == CMD_SRST) begin
      soft_resets++;
      soft_reset_model();
      `uvm_info("SCB", "Soft reset accepted: board cleared, expecting 1 initial tile", UVM_MEDIUM)
      return;
    end

    if (game_won || game_over) begin
      blocked_moves++;
      awaiting_spawn = 1'b0;
      `uvm_info("SCB", $sformatf("Move cmd=%0d blocked (won=%0b over=%0b)", cmd, game_won, game_over), UVM_MEDIUM)
      return;
    end

    dir = cmd - 1;
    total_moves++;
    moved = apply_move(dir, got_2048);

    if (moved) begin
      valid_moves++;
      dir_fail_flags = 4'b0000;             
      spawn_wait     = 0;
      if (got_2048) begin
        game_won       = 1'b1;
        wins_seen++;
        awaiting_spawn = 1'b0;                   
      end
      else begin
        awaiting_spawn = 1'b1;
      end
      `uvm_info("SCB", $sformatf("Move %0d dir=%0d valid (won=%0b) awaiting_spawn=%0b",
                total_moves, dir, game_won, awaiting_spawn), UVM_MEDIUM)
    end
    else begin
      invalid_moves++;
      awaiting_spawn      = 1'b0;               
      dir_fail_flags[dir] = 1'b1;                
      if (dir_fail_flags == 4'b1111 && !game_over) begin
        game_over = 1'b1;                        
        losses_seen++;
      end
      `uvm_info("SCB", $sformatf("Move %0d dir=%0d invalid: no spawn, dir_fail_flags=4'b%04b game_over=%0b",
                total_moves, dir, dir_fail_flags, game_over), UVM_MEDIUM)
    end
  endfunction

  function void step_debouncer(logic [4:0] btn);
    int cur_cmd;

    if ($isunknown(btn)) return;
    cur_cmd = pick_cmd(btn);

    if (!btn_held) begin
      if (cur_cmd == CMD_NONE) begin
        cand_cmd  = CMD_NONE;
        press_cnt = 0;
      end
      else if (cur_cmd != cand_cmd) begin
        cand_cmd  = cur_cmd;                     
        press_cnt = 1;
      end
      else begin
        press_cnt++;
      end

      if (press_cnt >= 2) begin
        btn_held    = 1'b1;
        held_cmd    = cand_cmd;
        release_cnt = 0;
        execute_cmd(held_cmd);
      end
    end
    else begin
      if (btn[held_cmd - 1] == 1'b0) begin
        release_cnt++;
        if (release_cnt >= 2) begin
          btn_held  = 1'b0;
          cand_cmd  = CMD_NONE;
          press_cnt = 0;
        end
      end
      else begin
        release_cnt = 0;
      end
    end
  endfunction

  function bit glyph_on(int e, int cx, int cy);
    int gcol, grow;

    if (cy < 16 || cy >= 48) return 1'b0;        
    grow = (cy - 16) / 2;

    if (e <= 6) begin
      if (cx < 16 || cx >= 48) return 1'b0;
      gcol = (cx - 16) / 2;
    end
    else if (e == EXP_WIN) begin
      if (cx + 2 >= CELL_SIZE) return 1'b0;
      gcol = (cx + 2) / 4;
    end
    else begin
      gcol = cx / 4;
    end
    return glyph[e][grow][15 - gcol];
  endfunction

  function logic [5:0] expected_rgb(int x, int y);
    int cx, cy, r, c, e;

    if (x >= H_ACTIVE || y >= V_ACTIVE) return RGB_BLACK;      

    if (x < BOARD_X0 || x >= BOARD_X0 + BOARD_SIZE ||
        y < BOARD_Y0 || y >= BOARD_Y0 + BOARD_SIZE) begin
      if (game_won)  return RGB_WIN_BG;                        
      if (game_over) return RGB_LOSS_BG;
      return RGB_BLACK;
    end

    c  = (x - BOARD_X0) / CELL_SIZE;
    r  = (y - BOARD_Y0) / CELL_SIZE;
    cx = (x - BOARD_X0) % CELL_SIZE;
    cy = (y - BOARD_Y0) % CELL_SIZE;
    e  = model_grid[r][c];

    if (e == EXP_EMPTY) begin
      if (cx >= empty_dot_lo && cx < empty_dot_lo + 2 &&
          cy >= empty_dot_lo && cy < empty_dot_lo + 2)
        return RGB_WHITE;
      return RGB_EMPTY_BG;
    end

    if (glyph_on(e, cx, cy)) return RGB_BLACK;
    return tile_rgb[e];
  endfunction

  function string where_is(int x, int y);
    int r, c, cx, cy;
    if (x >= H_ACTIVE || y >= V_ACTIVE)
      return "blanking region";
    if (x < BOARD_X0 || x >= BOARD_X0 + BOARD_SIZE ||
        y < BOARD_Y0 || y >= BOARD_Y0 + BOARD_SIZE)
      return $sformatf("outside board (won=%0b over=%0b)", game_won, game_over);
    c  = (x - BOARD_X0) / CELL_SIZE;
    r  = (y - BOARD_Y0) / CELL_SIZE;
    cx = (x - BOARD_X0) % CELL_SIZE;
    cy = (y - BOARD_Y0) % CELL_SIZE;
    return $sformatf("cell[row %0d][col %0d] exp=%0d (tile %0d) local(cx=%0d, cy=%0d)",
                     r, c, model_grid[r][c], tile_val(model_grid[r][c]), cx, cy);
  endfunction

  function void observe_cell_corner(int x, int y, logic [5:0] act_rgb);
    int r, c, cx, cy, dut_e;

    if (x < BOARD_X0 || x >= BOARD_X0 + BOARD_SIZE ||
        y < BOARD_Y0 || y >= BOARD_Y0 + BOARD_SIZE) return;

    cx = (x - BOARD_X0) % CELL_SIZE;
    cy = (y - BOARD_Y0) % CELL_SIZE;
    if (cx != 0 || cy != 0) return;

    c = (x - BOARD_X0) / CELL_SIZE;
    r = (y - BOARD_Y0) / CELL_SIZE;
    dut_e = exp_of_rgb(act_rgb);

    if (dut_e < 0) begin
      unknown_colour_errors++;
      if (unknown_colour_errors <= 20) begin
        `uvm_error("SCB_COLOUR_UNKNOWN",
          $sformatf("Frame %0d cell[%0d][%0d]: colour %s is not in the spec table (model exp=%0d)",
                    complete_frames + 1, r, c, rgb_str(act_rgb), model_grid[r][c]))
      end
      return;
    end

    if (dut_e == model_grid[r][c]) return;

    if (awaiting_spawn && model_grid[r][c] == EXP_EMPTY && (dut_e == 1 || dut_e == 2)) begin
      model_grid[r][c] = dut_e;
      awaiting_spawn   = 1'b0;
      spawn_wait       = 0;
      spawn_pos[r][c]++;
      if (dut_e == 1) spawn_2_cnt++;
      else            spawn_4_cnt++;
      `uvm_info("SCB", $sformatf("Valid spawn: tile %0d at cell[%0d][%0d]", tile_val(dut_e), r, c), UVM_MEDIUM)
    end
    else if (model_grid[r][c] == EXP_EMPTY) begin
      cell_errors++;
      `uvm_error("SCB_ILLEGAL_SPAWN",
        $sformatf("Frame %0d cell[%0d][%0d]: tile %0d appeared on an empty cell but no legal spawn (awaiting_spawn=%0b, allowed 2 or 4)",
                  complete_frames + 1, r, c, tile_val(dut_e), awaiting_spawn))
      model_grid[r][c] = dut_e;                  
      awaiting_spawn   = 1'b0;
    end
    else begin
      cell_errors++;
      `uvm_error("SCB_CELL_MISMATCH",
        $sformatf("Frame %0d cell[%0d][%0d]: model exp=%0d (tile %0d), DUT exp=%0d (tile %0d). Slide/merge error or spawn on occupied cell",
                  complete_frames + 1, r, c, model_grid[r][c], tile_val(model_grid[r][c]), dut_e, tile_val(dut_e)))
      model_grid[r][c] = dut_e;                  
    end
  endfunction

  function void process_sample(logic rst_n, logic [4:0] btn, logic [7:0] uo);
    logic       vsync;
    logic [5:0] act_rgb, exp_rgb;
    bit         vs_fall;
    if (rst_n === 1'b0) begin
      if (!in_hard_reset) begin
        hard_reset();
        in_hard_reset = 1'b1;
        hard_resets++;
        `uvm_info("SCB", "Hard reset asserted (rst_n=0): model and pixel tracker reset", UVM_MEDIUM)
      end
      return;
    end
    in_hard_reset = 1'b0;

    vsync   = uo[3];
    act_rgb = {uo[0], uo[4], uo[1], uo[5], uo[2], uo[6]};   
    vs_fall = (prev_vsync == 1'b1) && (vsync === 1'b0);

    if (vs_fall) begin
      if (locked) begin
        complete_frames++;

        if (frame_bad_px > 0) begin
          bad_frames++;
          if (bad_frames <= max_frame_msgs) begin
            `uvm_error("SCB_FRAME_MISMATCH",
              $sformatf("Frame %0d: %0d of %0d pixels differ from the expected frame",
                        complete_frames, frame_bad_px, H_TOTAL * V_TOTAL))
          end
        end
        frame_bad_px       = 0;
        frame_msgs_printed = 0;

        if (awaiting_spawn) begin
          spawn_wait++;
          if (spawn_wait >= SPAWN_WAIT_FALLS) begin
            `uvm_error("SCB_NO_SPAWN",
              $sformatf("Valid move or soft reset but no tile appeared within %0d frames", SPAWN_WAIT_FALLS))
            awaiting_spawn = 1'b0;
          end
        end
        step_debouncer(btn_sync2);
      end
      locked = 1'b1;
      pix_x  = VSYNC_FALL_X;
      pix_y  = VSYNC_FALL_Y;
    end
    else if (pix_x == H_TOTAL - 1) begin
      pix_x = 0;
      if (pix_y == V_TOTAL - 1) pix_y = 0;
      else                      pix_y = pix_y + 1;
    end
    else begin
      pix_x = pix_x + 1;
    end
    if (locked) begin
      observe_cell_corner(pix_x, pix_y, act_rgb);

      exp_rgb = expected_rgb(pix_x, pix_y);
      total_pixels++;
      if (act_rgb === exp_rgb) begin
        matched_pixels++;
      end
      else begin
        mismatched_pixels++;
        frame_bad_px++;
        if (frame_msgs_printed < max_px_msgs_per_frame && total_msgs_printed < max_px_msgs_total) begin
          frame_msgs_printed++;
          total_msgs_printed++;
          `uvm_error("SCB_PIXEL_MISMATCH",
            $sformatf("Frame %0d pixel(x=%0d, y=%0d) %s : expected RGB=%s, actual RGB=%s",
                      complete_frames + 1, pix_x, pix_y, where_is(pix_x, pix_y),
                      rgb_str(exp_rgb), rgb_str(act_rgb)))
        end
      end
    end
    btn_sync2  = btn_sync1;
    btn_sync1  = btn;
    prev_vsync = (vsync === 1'b1);
  endfunction
  
  function void backdoor_sync_grid(int preloaded [GRID_N][GRID_N]);
    for (int r = 0; r < GRID_N; r++)
      for (int c = 0; c < GRID_N; c++)
        model_grid[r][c] = preloaded[r][c];
    game_won       = 1'b0;
    game_over      = 1'b0;
    dir_fail_flags = 4'b0000;
    awaiting_spawn = 1'b0;
    spawn_wait     = 0;
    `uvm_info("SCB", "Backdoor preload synced to scoreboard model_grid", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    seq_item in_pkt, out_pkt;
    forever begin
      fifo_in.get(in_pkt);
      fifo_op.get(out_pkt);
      process_sample(in_pkt.rst_n, in_pkt.ui_in[4:0], out_pkt.uo_out);
    end
  endtask

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (complete_frames == 0) begin
      `uvm_error("SCB_ZERO_FRAMES", "No complete frame was checked: scoreboard result is vacuous")
    end
    if (awaiting_spawn) begin
      `uvm_error("SCB_PENDING_SPAWN", "Simulation ended while an expected tile spawn was unresolved")
    end
    if (mismatched_pixels > 0) begin
      `uvm_error("SCB_FAIL", $sformatf("%0d pixel mismatches in %0d frame(s), %0d pixels compared",
                 mismatched_pixels, bad_frames, total_pixels))
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCB_SUMMARY", "====================================================", UVM_NONE)
    `uvm_info("SCB_SUMMARY", $sformatf(" Complete frames       : %0d", complete_frames), UVM_NONE)
    `uvm_info("SCB_SUMMARY", $sformatf(" Hard / soft resets    : %0d / %0d", hard_resets, soft_resets), UVM_NONE)
    `uvm_info("SCB_SUMMARY", $sformatf(" Moves valid / invalid : %0d / %0d (blocked %0d)",
              valid_moves, invalid_moves, blocked_moves), UVM_NONE)
    `uvm_info("SCB_SUMMARY", $sformatf(" Wins / losses seen    : %0d / %0d", wins_seen, losses_seen), UVM_NONE)
    `uvm_info("SCB_SUMMARY", $sformatf(" Spawns 2 / 4          : %0d / %0d", spawn_2_cnt, spawn_4_cnt), UVM_NONE)
    for (int r = 0; r < GRID_N; r++) begin
      `uvm_info("SCB_SUMMARY", $sformatf(" Spawn count row %0d    : %0d %0d %0d %0d", r,
                spawn_pos[r][0], spawn_pos[r][1], spawn_pos[r][2], spawn_pos[r][3]), UVM_NONE)
    end
    `uvm_info("SCB_SUMMARY", $sformatf(" Pixels matched / failed: %0d / %0d", matched_pixels, mismatched_pixels), UVM_NONE)
    `uvm_info("SCB_SUMMARY", $sformatf(" Cell / spawn errors   : %0d", cell_errors), UVM_NONE)
    `uvm_info("SCB_SUMMARY", " Final model grid (exponents):", UVM_NONE)
    for (int r = 0; r < GRID_N; r++) begin
      `uvm_info("SCB_SUMMARY", $sformatf("   Row %0d: [ %2d %2d %2d %2d ]", r,
                model_grid[r][0], model_grid[r][1], model_grid[r][2], model_grid[r][3]), UVM_NONE)
    end
    `uvm_info("SCB_SUMMARY", "====================================================", UVM_NONE)
  endfunction
endclass


