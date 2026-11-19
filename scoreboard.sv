// 

class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)

    uvm_tlm_analysis_fifo #(seq_item) fifo_in;
    uvm_tlm_analysis_fifo #(seq_item) fifo_op;

    // -------------------------------------------------------------------------
    // Exact 16x16 Glyph Bitmaps from vga_controller.v
    // -------------------------------------------------------------------------
    localparam [255:0] TILE_2 = {
        16'b0000000000000000, 16'b0000000000000000, 16'b0000111111110000, 16'b0000111111110000,
        16'b0000000000110000, 16'b0000000000110000, 16'b0000000000110000, 16'b0000111111110000,
        16'b0000111111110000, 16'b0000110000000000, 16'b0000110000000000, 16'b0000110000000000,
        16'b0000111111110000, 16'b0000111111110000, 16'b0000000000000000, 16'b0000000000000000
    };
    localparam [255:0] TILE_4 = {
        16'b0000000000000000, 16'b0000000000000000, 16'b0000110000110000, 16'b0000110000110000,
        16'b0000110000110000, 16'b0000110000110000, 16'b0000110000110000, 16'b0000111111110000,
        16'b0000111111110000, 16'b0000000000110000, 16'b0000000000110000, 16'b0000000000110000,
        16'b0000000000110000, 16'b0000000000110000, 16'b0000000000000000, 16'b0000000000000000
    };
    localparam [255:0] TILE_8 = {
        16'b0000000000000000, 16'b0000000000000000, 16'b0000111111110000, 16'b0000111111110000,
        16'b0000110000110000, 16'b0000110000110000, 16'b0000110000110000, 16'b0000111111110000,
        16'b0000111111110000, 16'b0000110000110000, 16'b0000110000110000, 16'b0000110000110000,
        16'b0000111111110000, 16'b0000111111110000, 16'b0000000000000000, 16'b0000000000000000
    };
    localparam [255:0] TILE_16 = {
        16'b0000000000000000, 16'b0000000000000000, 16'b0001100111111000, 16'b0111100111111000,
        16'b0111100110000000, 16'b0001100110000000, 16'b0001100110000000, 16'b0001100111111100,
        16'b0001100111111100, 16'b0001100110001100, 16'b0001100110001100, 16'b0001100110001100,
        16'b0001100111111100, 16'b0001100111111100, 16'b0000000000000000, 16'b0000000000000000
    };
    localparam [255:0] TILE_32 = {
        16'b0000000000000000, 16'b0000000000000000, 16'b0111111001111110, 16'b0111111001111110,
        16'b0000011000000110, 16'b0000011000000110, 16'b0000011000000110, 16'b0111111001111110,
        16'b0111111001111110, 16'b0000011001100000, 16'b0000011001100000, 16'b0000011001100000,
        16'b0111111001111110, 16'b0111111001111110, 16'b0000000000000000, 16'b0000000000000000
    };
    localparam [255:0] TILE_64 = {
        16'b0000000000000000, 16'b0000000000000000, 16'b1111110001100011, 16'b1111110001100011,
        16'b1100000001100011, 16'b1100000001100011, 16'b1100000001100011, 16'b1111111001111111,
        16'b1111111001111111, 16'b1100011000000011, 16'b1100011000000011, 16'b1100011000000011,
        16'b1111111000000011, 16'b1111111000000011, 16'b0000000000000000, 16'b0000000000000000
    };
    localparam [255:0] TILE_128 = {
        16'b0000000000000000, 16'b0000000000000000, 16'b0000101110111000, 16'b0001101110111000,
        16'b0001100010101000, 16'b0000100010101000, 16'b0000100010101000, 16'b0000101110111000,
        16'b0000101110111000, 16'b0000101000101000, 16'b0000101000101000, 16'b0000101000101000,
        16'b0000101110111000, 16'b0000101110111000, 16'b0000000000000000, 16'b0000000000000000
    };
    localparam [255:0] TILE_256 = {
        16'b0000000000000000, 16'b0000000000000000, 16'b0001110111011100, 16'b0001110111011100,
        16'b0000010100010000, 16'b0000010100010000, 16'b0000010100010000, 16'b0001110111011100,
        16'b0001110111011100, 16'b0001000001010100, 16'b0001000001010100, 16'b0001000001010100,
        16'b0001110111011100, 16'b0001110111011100, 16'b0000000000000000, 16'b0000000000000000
    };
    localparam [255:0] TILE_512 = {
        16'b0000000000000000, 16'b0000000000000000, 16'b0001110010111000, 16'b0001110110111000,
        16'b0001000110001000, 16'b0001000010001000, 16'b0001000010001000, 16'b0001110010111000,
        16'b0001110010111000, 16'b0000010010100000, 16'b0000010010100000, 16'b0000010010100000,
        16'b0001110010111000, 16'b0001110010111000, 16'b0000000000000000, 16'b0000000000000000
    };
    localparam [255:0] TILE_1024 = {
        16'b0000000000000000, 16'b0000000000000000, 16'b0010111011101010, 16'b0110111011101010,
        16'b0110101000101010, 16'b0010101000101010, 16'b0010101000101010, 16'b0010101011101110,
        16'b0010101011101110, 16'b0010101010000010, 16'b0010101010000010, 16'b0010101010000010,
        16'b0010111011100010, 16'b0010111011100010, 16'b0000000000000000, 16'b0000000000000000
    };
    localparam [255:0] TILE_2048 = {
        16'b0000000000000000, 16'b0000000000000000, 16'b0111011101010111, 16'b0111011101010111,
        16'b0001010101010101, 16'b0001010101010101, 16'b0001010101010101, 16'b0111010101110111,
        16'b0111010101110111, 16'b0100010100010101, 16'b0100010100010101, 16'b0100010100010101,
        16'b0111011100010111, 16'b0111011100010111, 16'b0000000000000000, 16'b0000000000000000
    };

    localparam int H_DISPLAY    = 640;
    localparam int H_SYNC_START = 656;
    localparam int H_MAX        = 799;
    localparam int V_DISPLAY    = 480;
    localparam int V_SYNC_START = 490;
    localparam int V_MAX        = 524;

    localparam int BOARD_SIZE   = 256;
    localparam int BOARD_X      = 192;
    localparam int BOARD_Y      = 112;

    // Reference Model State
    logic [3:0] ref_grid[0:3][0:3];
    bit         ref_won;
    bit         ref_lost;
    logic [3:0] ref_game_over;
    bit         awaiting_valid_spawn; // True ONLY after s_rst or a valid board-changing move

    // Shadow 2-stage input synchronizer + 2-VSYNC debouncer
    logic [4:0] sync01, sync02;
    logic [1:0] deb_ps;
    logic       deb_count;
    logic [2:0] deb_sel_lines;
    logic       deb_vsync_reg;
    bit         prev_deb_srst;
    logic [3:0] prev_deb_y;

    int         pix_x;
    int         pix_y;
    bit         prev_hsync;
    bit         prev_vsync;
    bit         sync_locked;

    longint unsigned total_pixels_checked;
    longint unsigned matched_pixels;
    longint unsigned mismatched_pixels;
    int unsigned     frames_verified;
    int unsigned     moves_verified;

    function new(string name = "scoreboard", uvm_component parent = null);
        super.new(name, parent);
        fifo_in = new("fifo_in", this);
        fifo_op = new("fifo_op", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        hard_reset_model();
        pix_x                = 0;
        pix_y                = 0;
        prev_hsync           = 1'b1;
        prev_vsync           = 1'b1;
        sync_locked          = 1'b0;
        total_pixels_checked = 0;
        matched_pixels       = 0;
        mismatched_pixels    = 0;
        frames_verified      = 0;
        moves_verified       = 0;
    endfunction

    function void hard_reset_model();
        for (int r = 0; r < 4; r++)
            for (int c = 0; c < 4; c++)
                ref_grid[r][c] = 4'd0;
        ref_won              = 1'b0;
        ref_lost             = 1'b0;
        ref_game_over        = 4'd0;
        awaiting_valid_spawn = 1'b0;
        sync01               = 5'd0;
        sync02               = 5'd0;
        deb_ps               = 2'd0;
        deb_count            = 1'b0;
        deb_sel_lines        = 3'd0;
        deb_vsync_reg        = 1'b0;
        prev_deb_srst        = 1'b0;
        prev_deb_y           = 4'd0;
    endfunction

    // -------------------------------------------------------------------------
    // 2048 Slide & Merge Logic
    // -------------------------------------------------------------------------
    function void compress_merge_line(input logic [3:0] in_l[4], output logic [3:0] out_l[4]);
        logic [3:0] tmp[4];
        int idx = 0;
        for (int k = 0; k < 4; k++) begin
            tmp[k]   = 4'd0;
            out_l[k] = 4'd0;
        end
        for (int k = 0; k < 4; k++) begin
            if (in_l[k] != 4'd0) begin
                tmp[idx] = in_l[k];
                idx++;
            end
        end
        idx = 0;
        for (int k = 0; k < 4; k++) begin
            if (tmp[k] == 4'd0) continue;
            if (k < 3 && tmp[k] == tmp[k + 1]) begin
                out_l[idx] = tmp[k] + 4'd1;
                if (out_l[idx] == 4'd11)
                    ref_won = 1'b1;
                idx++;
                k++;
            end else begin
                out_l[idx] = tmp[k];
                idx++;
            end
        end
    endfunction

    function void execute_rtl_move(logic [3:0] y_dir);
        logic [3:0] line[4], merged[4];
        bit changed = 1'b0;
        int dir = -1; // 0=U, 1=D, 2=L, 3=R

        if (ref_won || (&ref_game_over)) return;

        if      (y_dir[3]) dir = 0; // U
        else if (y_dir[2]) dir = 1; // D
        else if (y_dir[1]) dir = 2; // L
        else if (y_dir[0]) dir = 3; // R
        if (dir == -1) return;

        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                case (dir)
                    0: line[j] = ref_grid[j][i];
                    1: line[j] = ref_grid[3 - j][i];
                    2: line[j] = ref_grid[i][j];
                    3: line[j] = ref_grid[i][3 - j];
                endcase
            end
            compress_merge_line(line, merged);
            for (int j = 0; j < 4; j++) begin
                logic [3:0] old_v;
                case (dir)
                    0: begin old_v = ref_grid[j][i];     ref_grid[j][i]     = merged[j]; end
                    1: begin old_v = ref_grid[3 - j][i]; ref_grid[3 - j][i] = merged[j]; end
                    2: begin old_v = ref_grid[i][j];     ref_grid[i][j]     = merged[j]; end
                    3: begin old_v = ref_grid[i][3 - j]; ref_grid[i][3 - j] = merged[j]; end
                endcase
                if (old_v != merged[j]) changed = 1'b1;
            end
        end

        moves_verified++;
        if (changed) begin
            ref_game_over        = 4'd0;
            awaiting_valid_spawn = !ref_won;
            `uvm_info("SCB", $sformatf("Move %0d (dir=%0d): valid move -> awaiting 1 new spawned tile",
                      moves_verified, dir), UVM_LOW)
        end else begin
            ref_game_over        = ref_game_over | {y_dir[2], y_dir[3], y_dir[0], y_dir[1]};
            ref_lost             = &ref_game_over;
            awaiting_valid_spawn = 1'b0; // Invalid move MUST NOT spawn a tile!
            `uvm_info("SCB", $sformatf("Move %0d (dir=%0d): invalid move (no board change) -> NO spawn allowed",
                      moves_verified, dir), UVM_LOW)
        end
    endfunction

    // -------------------------------------------------------------------------
    // Exact Pixel Predictor (Matches vga_controller.v & tt_um_2048.v)
    // -------------------------------------------------------------------------
    function bit [5:0] predict_vga_rgb(int px, int py);
        bit video_active, inside_board;
        bit [7:0] rel_x, rel_y;
        bit [1:0] row, col;
        bit [5:0] cell_x, cell_y;
        bit [3:0] val;
        bit center, is_large, in_y_range, in_x_range, inside_text_box;
        bit [5:0] cell_x_plus2;
        bit [3:0] gy, gx_small, gx_large_std, gx_large_off, gx;
        bit [7:0] bit_index;
        bit glyph_pixel;
        bit [5:0] bg_colour, tile_colour;

        video_active = (px < H_DISPLAY) && (py < V_DISPLAY);
        if (!video_active)
            return 6'b00_00_00;

        inside_board = (px >= BOARD_X && px < BOARD_X + BOARD_SIZE) &&
                       (py >= BOARD_Y && py < BOARD_Y + BOARD_SIZE);

        if (!inside_board)
            return ref_won ? 6'b00_10_01 : (ref_lost ? 6'b11_00_00 : 6'b00_00_00);

        rel_x  = px[7:0] - BOARD_X[7:0];
        rel_y  = py[7:0] - BOARD_Y[7:0];
        col    = rel_x[7:6];
        row    = rel_y[7:6];
        cell_x = rel_x[5:0];
        cell_y = rel_y[5:0];
        val    = ref_grid[row][col];

        center          = (cell_x[5:1] == 5'd15) && (cell_y[5:1] == 5'd15);
        is_large        = (val >= 4'd7);
        in_y_range      = (cell_y >= 6'd16 && cell_y < 6'd48);
        in_x_range      = is_large ? 1'b1 : (cell_x >= 6'd16 && cell_x < 6'd48);
        inside_text_box = in_y_range && in_x_range;

        cell_x_plus2 = cell_x + 6'd2;
        gy           = (cell_y >= 6'd16) ? (cell_y[4:1] - 4'd8) : 4'd0;
        gx_small     = (cell_x >= 6'd16) ? (cell_x[4:1] - 4'd8) : 4'd0;
        gx_large_std = cell_x[5:2];
        gx_large_off = cell_x_plus2[5:2];
        gx           = is_large ? ((val == 4'd11) ? gx_large_off : gx_large_std) : gx_small;
        bit_index    = ~{gy, gx};

        case (val)
            4'h1: glyph_pixel = TILE_2[bit_index];
            4'h2: glyph_pixel = TILE_4[bit_index];
            4'h3: glyph_pixel = TILE_8[bit_index];
            4'h4: glyph_pixel = TILE_16[bit_index];
            4'h5: glyph_pixel = TILE_32[bit_index];
            4'h6: glyph_pixel = TILE_64[bit_index];
            4'h7: glyph_pixel = TILE_128[bit_index];
            4'h8: glyph_pixel = TILE_256[bit_index];
            4'h9: glyph_pixel = TILE_512[bit_index];
            4'hA: glyph_pixel = TILE_1024[bit_index];
            4'hB: glyph_pixel = TILE_2048[bit_index];
            default: glyph_pixel = 1'b0;
        endcase

        case (val)
            4'h0: bg_colour = center ? 6'b11_11_11 : 6'b01_01_01;
            4'h1: bg_colour = 6'b11_01_01;
            4'h2: bg_colour = 6'b11_10_01;
            4'h3: bg_colour = 6'b11_11_01;
            4'h4: bg_colour = 6'b00_11_11;
            4'h5: bg_colour = 6'b00_10_11;
            4'h6: bg_colour = 6'b00_11_10;
            4'h7: bg_colour = 6'b00_11_01;
            4'h8: bg_colour = 6'b11_01_00;
            4'h9: bg_colour = 6'b11_01_10;
            4'hA: bg_colour = 6'b10_01_11;
            4'hB: bg_colour = 6'b11_00_01;
            default: bg_colour = center ? 6'b11_11_11 : 6'b01_01_01;
        endcase

        tile_colour = (inside_text_box && glyph_pixel) ? 6'b00_00_00 : bg_colour;
        return tile_colour;
    endfunction

    // -------------------------------------------------------------------------
    // Cycle-by-Cycle Lockstep Verification
    // -------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        seq_item in_pkt, out_pkt;
        bit cur_hsync, cur_vsync;
        bit [5:0] actual_rgb, expected_rgb;
        logic [2:0] enc_sel;
        logic mux_btn, tick, deb_out;
        bit deb_srst;
        logic [3:0] deb_y;

        forever begin
            fifo_in.get(in_pkt);
            fifo_op.get(out_pkt);

            cur_hsync = out_pkt.uo_out[7];
            cur_vsync = out_pkt.uo_out[3];

            // 1. Step shadow 2-FF sync + 2-VSYNC debouncer
            if      (sync02[4]) enc_sel = 3'd0;
            else if (sync02[3]) enc_sel = 3'd4;
            else if (sync02[2]) enc_sel = 3'd5;
            else if (sync02[1]) enc_sel = 3'd6;
            else if (sync02[0]) enc_sel = 3'd7;
            else                enc_sel = 3'd1;

            case (deb_sel_lines[1:0])
                2'b00: mux_btn = sync02[3];
                2'b01: mux_btn = sync02[2];
                2'b10: mux_btn = sync02[1];
                2'b11: mux_btn = sync02[0];
            endcase
            if (!deb_sel_lines[2]) mux_btn = sync02[4];

            tick    = deb_vsync_reg & ~cur_vsync;
            deb_out = (deb_ps == 2'd2 || deb_ps == 2'd3);

            deb_srst = 1'b0;
            deb_y    = 4'd0;
            if (deb_out) begin
                case (deb_sel_lines)
                    3'd0: deb_srst = 1'b1;
                    3'd4: deb_y    = 4'b0001;
                    3'd5: deb_y    = 4'b0010;
                    3'd6: deb_y    = 4'b0100;
                    3'd7: deb_y    = 4'b1000;
                    default: begin deb_srst = 1'b0; deb_y = 4'd0; end
                endcase
            end

            // Trigger reference grid update on debounced rising edges
            if (deb_srst && !prev_deb_srst) begin
                for (int r = 0; r < 4; r++)
                    for (int c = 0; c < 4; c++)
                        ref_grid[r][c] = 4'd0;
                ref_won              = 1'b0;
                ref_lost             = 1'b0;
                ref_game_over        = 4'd0;
                awaiting_valid_spawn = 1'b1;
                `uvm_info("SCB", "Debounced s_rst -> cleared grid & awaiting 1 initial spawned tile", UVM_LOW)
            end else if (deb_y != 4'd0 && prev_deb_y == 4'd0) begin
                execute_rtl_move(deb_y);
            end
            prev_deb_srst = deb_srst;
            prev_deb_y    = deb_y;

            // Advance debouncer FSM & 2-FF sync registers
            case (deb_ps)
                2'd0: if (mux_btn) deb_ps = 2'd1;
                2'd1: begin
                    if (deb_sel_lines != enc_sel) begin
                        deb_ps = 2'd0; deb_count = 1'b0;
                    end else if (mux_btn) begin
                        if (tick) begin
                            if (deb_count) begin deb_ps = 2'd2; deb_count = 1'b0; end
                            else deb_count = 1'b1;
                        end
                    end else begin
                        deb_ps = 2'd0; deb_count = 1'b0;
                    end
                end
                2'd2: if (!mux_btn) deb_ps = 2'd3;
                2'd3: begin
                    if (!mux_btn) begin
                        if (tick) begin
                            if (deb_count) begin deb_ps = 2'd0; deb_count = 1'b0; end
                            else deb_count = 1'b1;
                        end
                    end else begin
                        deb_ps = 2'd2; deb_count = 1'b0;
                    end
                end
            endcase
            if (deb_ps == 2'd0) deb_sel_lines = enc_sel;
            deb_vsync_reg = cur_vsync;
            sync02        = sync01;
            sync01        = in_pkt.ui_in[4:0];

            // 2. Exact hvsync_generator.v pix_x / pix_y tracking
            if (prev_vsync == 1'b1 && cur_vsync == 1'b0 && cur_hsync == 1'b1) begin
                pix_x       = 1;
                pix_y       = V_SYNC_START;
                sync_locked = 1'b1;
                frames_verified++;
            end else if (prev_hsync == 1'b1 && cur_hsync == 1'b0) begin
                pix_x = H_SYNC_START + 1;
            end else begin
                if (pix_x == H_MAX) begin
                    pix_x = 0;
                    pix_y = (pix_y == V_MAX) ? 0 : (pix_y + 1);
                end else begin
                    pix_x = pix_x + 1;
                end
            end
            prev_hsync = cur_hsync;
            prev_vsync = cur_vsync;

            // 3. Pixel-by-Pixel Comparison
            if (sync_locked) begin
                actual_rgb = {out_pkt.uo_out[0], out_pkt.uo_out[4],
                              out_pkt.uo_out[1], out_pkt.uo_out[5],
                              out_pkt.uo_out[2], out_pkt.uo_out[6]};

                // Lock in valid spawned tile (2 or 4) on an empty cell ONLY when awaiting_valid_spawn == 1
                if (awaiting_valid_spawn &&
                    pix_x >= BOARD_X && pix_x < BOARD_X + BOARD_SIZE &&
                    pix_y >= BOARD_Y && pix_y < BOARD_Y + BOARD_SIZE) begin
                    int r_idx  = (pix_y - BOARD_Y) / 64;
                    int c_idx  = (pix_x - BOARD_X) / 64;
                    int cell_x = (pix_x - BOARD_X) % 64;
                    int cell_y = (pix_y - BOARD_Y) % 64;

                    // Sample top-left corner of cell (cell_x=0, cell_y=0), which is always pure bg_colour
                    if (ref_grid[r_idx][c_idx] == 4'd0 && cell_x == 0 && cell_y == 0) begin
                        if (actual_rgb == 6'b11_01_01) begin
                            ref_grid[r_idx][c_idx] = 4'd1; // Tile '2'
                            awaiting_valid_spawn   = 1'b0;
                            `uvm_info("SCB", $sformatf("RTL spawned valid tile '2' at [%0d][%0d]", r_idx, c_idx), UVM_LOW)
                        end else if (actual_rgb == 6'b11_10_01) begin
                            ref_grid[r_idx][c_idx] = 4'd2; // Tile '4'
                            awaiting_valid_spawn   = 1'b0;
                            `uvm_info("SCB", $sformatf("RTL spawned valid tile '4' at [%0d][%0d]", r_idx, c_idx), UVM_LOW)
                        end
                    end
                end

                expected_rgb = predict_vga_rgb(pix_x, pix_y);
                total_pixels_checked++;

                if (actual_rgb === expected_rgb) begin
                    matched_pixels++;
                end else begin
                    mismatched_pixels++;
                    if (mismatched_pixels <= 20) begin
                        `uvm_error("SCB_MISMATCH",
                                   $sformatf("Pixel mismatch at (pix_x=%0d, pix_y=%0d) Frame %0d: expected RGB=6'b%06b, actual RGB=6'b%06b",
                                             pix_x, pix_y, frames_verified, expected_rgb, actual_rgb))
                    end
                end
            end
        end
    endtask

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCB_SUMMARY", "====================================================", UVM_LOW)
        `uvm_info("SCB_SUMMARY", $sformatf(" Frames Verified      : %0d", frames_verified), UVM_LOW)
        `uvm_info("SCB_SUMMARY", $sformatf(" Moves Processed      : %0d", moves_verified), UVM_LOW)
        `uvm_info("SCB_SUMMARY", $sformatf(" Total Pixels Checked : %0d", total_pixels_checked), UVM_LOW)
        `uvm_info("SCB_SUMMARY", $sformatf(" Matched Pixels       : %0d", matched_pixels), UVM_LOW)
        `uvm_info("SCB_SUMMARY", $sformatf(" Mismatched Pixels    : %0d", mismatched_pixels), UVM_LOW)
        `uvm_info("SCB_SUMMARY", " Final Reference 4x4 Board (Exponents):", UVM_LOW)
        for (int r = 0; r < 4; r++) begin
            `uvm_info("SCB_SUMMARY", $sformatf("   Row %0d: [ %2d  %2d  %2d  %2d ]",
                      r, ref_grid[r][0], ref_grid[r][1], ref_grid[r][2], ref_grid[r][3]), UVM_LOW)
        end
        `uvm_info("SCB_SUMMARY", "====================================================", UVM_LOW)
    endfunction
endclass