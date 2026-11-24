class scorebaord extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)
  uvm_tlm_analysis_fifo #(seq_item) fifo_in;
  uvm_tlm_analysis_fifo #(seq_item) fifo_op;

  localparam int H_ACTIVE=640;
  localparam int H_TOTAL=800;
  localparam int V_ACTIVE=480;
  localparam int V_TOTAL=525;
  localparam int V_FP=10;

  localparam int GRID_N=4;
  localparam int CELL_SIZE=64;
  localparam int BOARD_SIZE=256;
  localparam int BOARD_X0=192;
  localparam int BOARD_Y0=112;

  localparam int EXP_EMPTY=0;
  localparam int EXP_WIN=11;

  localparam int CMD_NONE=0;
  localparam int CMD_UP=1;
  localparam int CMD_DOWN=2;
  localparam int CMD_LEFT=3;
  localparam int CMD_RIGHT=4;
  localparam int CMD_SRSR=5;

  localparam int DIR_UP=0;
  localparam int DIR_DOWN=1;
  localparam int DIR_LEFT=2;
  localparam int DIR_RIGHT=3;

  localparam int [5:0]RGB_BLACK=6'b000000;
  localparam int [5:0]RGB_WHITE=6'b111111;
  localparam int [5:0]RGB_EMPTY=6'b010101;
  localparam int [5:0]RGB_WIN=6'b001001;
  localparam int [5:0]RGB_LOSS=6'b110000;

  localparam int VSYNC_FALL_X=1;
  localparam int VSYNC_FALL_Y=490;
  localparam int SPAWN_WAIT_FALLS=2;

  bit[5:0]tile_rgb[12];
  bit[15:0]glyph[12][16];

  int model_grid[GRID_N][GRID_N];

  bit game_won;
  bit game_over;
  bit[3:0]dir_fail_flags;


  bit awaiting_spawn;
  int spawn_wait;
  logic [4:0]btn_sync1,btn_sync2;

  int cand_cmd;
  int press_cnt;
  int btn_held;
  int held_cmd;
  int release_cnt;

  bit in_hard_reset;

  bit locked;
  bit prev_vsync;
  int pix_x;
  int pix_y;

  int empty_dot_loc=30;

    int unsigned complete_frames;
    int unsigned hard_resets, soft_resets;
    int unsigned valid_moves, invalid_moves;
    int unsigned spawn_2_cnt, spawn_4_cnt;
    int unsigned cell_errors, missing_spawn_errors;
    int unsigned frame_bad_px;
    int unsigned pixel_msgs_printed;

    longint unsigned total_pixels;
    longint unsigned matched_pixels;
    longint unsigned mismatched_pixels;


  function new(string name="scorebaord",uvm_component parent=null);
    super.new(name,parent);
    fifo_in=new("fifo_in",this);
    fifo_op=new("fifo_op",this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    init_spec_tables();
    hard_reset();
  endfunction

  function void init_spec_tables();
        tile_rgb[0]  = RGB_EMPTY;
        tile_rgb[1]  = 6'b11_01_01; // 2
        tile_rgb[2]  = 6'b11_10_01; // 4
        tile_rgb[3]  = 6'b11_11_01; // 8
        tile_rgb[4]  = 6'b00_11_11; // 16
        tile_rgb[5]  = 6'b00_10_11; // 32
        tile_rgb[6]  = 6'b00_11_10; // 64
        tile_rgb[7]  = 6'b00_11_01; // 128
        tile_rgb[8]  = 6'b11_01_00; // 256
        tile_rgb[9]  = 6'b11_01_10; // 512
        tile_rgb[10] = 6'b10_01_11; // 1024
        tile_rgb[11] = 6'b11_00_01; // 2048

        for(int e=0;e<12;e++)begin
          for(int r=0;r<16;r++)begin
            glyph[e][r]=16'h0000;
          end
        end
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
    for(int r=0;r<GRID_N;r++)begin
      for(int c=0;c<GRID_N;c++)begin  
        model_grid[r][c]=EXP_EMPTY;
      end
    end

    game_won=0;
    game_over=0;
    fir_fail_flag=4'b0000;

    awaiting_spawn=1;
    spawn_wait=0;
    endfunction

    function void hard_reset();
      soft_reset_model();
      awaiting_spawn=0;
      btn_sync1=0;
      btn_sync=0;
      cand_cmd=CMD_NONE;
      press_cnt=0;
      btn_held=0;
      release_cnt=0;

      locked=0;
      prev_vsync=0;
      pix_x=0;
      pix_y=0;

      frame_bad_px=0;
      in_hard_reset=0;
    endfunction

    function int pick_cmd(logic[4:0]btn);
      if(btn[4])
        return CMD_SRST;
      if(btn[3])
        return CMD_RIGHT;
      if(btn[2])
        return CMD_LEFT;
      if(btn[2])
        return CMD_DOWN;
      if(btn[0])
        return CMD_UP;
    
    return CMD_NONE;
    endfunction

    function void step_debounce(logic [4:0]btn);
      int cur_cmd;
      if($isunknown(btn))
        return;
      cur_cmd=pick_cmd(btn);

      if(btn_held==0)begin
        if(cur_cmd==CMD_NONE)begin
          cand_cmd=CMD_NONE;
          press_cnt=0;
        end
        else if(cur_cmd!=cand_cmd)begin
          cand_cmd=cur_cmd;
          press_cnt=1;
        end
        else begin
          press_cnt++;
        end

        if(press_cnt>=2)begin
          btn_held=1;
          held_cmd=cand_cmd;
          release_cnt=0;
          execute_cmd(held_cmd);
          end
        end
      else begin
        if(btn[held_cmd-1]==0)begin
          release_cnt++;
          if(release_cnt>=2)begin
            btn_held=0;
            held_cmd=CMD_NONE;
            cand_cmd=CMD_NONE;
            press_cnt=0;
            release=-;
          end
        end
        else begin
          release_cnt=0;
        end
      end
      endfunction

      function void cell_of(int dir,int line_no,int pos,output int row,output int col);
        if(dir==DIR_LEFT)begin
          row=line_no;
          col=pos;
        end
        else if(dir==DIR_RIGHT)begin
          row=line_no;
          col=3-pos;
        end
        else if(dir==DIR_UP)begin 
          row=pos;
          col=line_no;
        end
        else begin
          row=3-pos;
          col=line_no;
        end
      endfunction

      function bit apply_move(int dir,output bit made_2048);
        int tiles[4];
        int result[4];
        int count;
        int read_idx;
        int write_idx;
        int row,col;
        bit changed=0;
        bit made_2048=0;
        for (int line_no = 0; line_no < 4; line_no++) begin
        for(int j=0;j<4;j++)begin
            tiles[j]=0;
            result[j]=0;
        end
        count=0;
        for(int pos=0;pos<4;pos++)begin
            cell_of(dir,line_no,pos,row,col);
            if(model_grid[row][col]!=EXP_EMPTY)begin
                tiles[count]=model_grid[row][col];
                count++;
            end
            read_idx=0;
            write_idx=0;
            while(read_idx<count)begin  
                if((read_idx+1<count)&&(tiles[read_idx]==tiles[read_idx+1]))begin
                    result[write_idx]=tile[read_idx]+1;
                    if(result[write_idx]==EXP_WIN)
                        made_2048=1;
                    read_idx=read_idx+2;
                end
                else begin
                    result[write_idx]=tiles[read_idx];
                    read_idx=read_idx+1;
                end
                write_idx++;
                end
                for(int pos=0;pos<4;pos++)begin
                    cell_of(dir,line_no,pos,row,col);
                    if(model_grid[row][col]!=result[pos])
                        changed=1;
                    model_grid[row][col]=result[pos];
                    end
                end
                return changed;
            endfunction

            function void execute_cmd(int cmd);
                bit moved;
                bit made_2048;
                int dir;
                if(cmd==CMD_SRST)begin
                    soft_reset++;
                    soft_reset_model();
                    return;
                end
                if(cmd<CMD_UP||cmd>CMD_RIGHT)
                    return;
                if(game_won||game_over)begin    
                    awaiting_spawn=0;
                    return;
                end
                dir=cmd-1;
                moved=apply_move(dir,mad_2048);
                if(moved)begin  
                    valid_moves++;
                    dir_fail_flags=4'b0000;
                    spawn_wait=0;
                    if(made_2048)begin
                        game_won=1;
                        awaiting_spawn=0;
                    end
                    else begin
                        awaiting_spawn=1;
                    end
                    end
                    else begin
                        
                    end


            



        

      




      





  endclass