class test extends uvm_test;
  `uvm_component_utils(test)

  environment envh;

  function new(string name = "test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    envh = environment::type_id::create("envh", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction

  task run_seq_with_drain(uvm_phase phase, uvm_sequence_base seqh);
    phase.raise_objection(this);
    phase.phase_done.set_drain_time(this, 100);
    seqh.start(envh.aa.seqrh);
    phase.drop_objection(this);
  endtask

  virtual task run_phase(uvm_phase phase);
    full_regression_seq reg_seqh;
    reg_seqh = full_regression_seq::type_id::create("reg_seqh");
    run_seq_with_drain(phase, reg_seqh);
  endtask
endclass

class game_smoke_test extends test;
  `uvm_component_utils(game_smoke_test)
  function new(string name = "game_smoke_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    game_smoke_seq seqh = game_smoke_seq::type_id::create("seqh");
    run_seq_with_drain(phase, seqh);
  endtask
endclass

class game_no_srst_gameover_test extends test;
  `uvm_component_utils(game_no_srst_gameover_test)
  function new(string name = "game_no_srst_gameover_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    game_no_srst_gameover_seq seqh = game_no_srst_gameover_seq::type_id::create("seqh");
    run_seq_with_drain(phase, seqh);
  endtask
endclass

class game_all_32_prio_test extends test;
  `uvm_component_utils(game_all_32_prio_test)
  function new(string name = "game_all_32_prio_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    game_all_32_prio_seq seqh = game_all_32_prio_seq::type_id::create("seqh");
    run_seq_with_drain(phase, seqh);
  endtask
endclass

class game_glitch_and_overlap_test extends test;
  `uvm_component_utils(game_glitch_and_overlap_test)
  function new(string name = "game_glitch_and_overlap_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    game_glitch_and_overlap_seq seqh = game_glitch_and_overlap_seq::type_id::create("seqh");
    run_seq_with_drain(phase, seqh);
  endtask
endclass

class game_merge_rules_test extends test;
  `uvm_component_utils(game_merge_rules_test)
  function new(string name = "game_merge_rules_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    game_merge_rules_seq seqh = game_merge_rules_seq::type_id::create("seqh");
    run_seq_with_drain(phase, seqh);
  endtask
endclass

class game_invalid_and_reset_test extends test;
  `uvm_component_utils(game_invalid_and_reset_test)
  function new(string name = "game_invalid_and_reset_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    game_invalid_and_reset_seq seqh = game_invalid_and_reset_seq::type_id::create("seqh");
    run_seq_with_drain(phase, seqh);
  endtask
endclass

class game_occupied_retry_test extends test;
  `uvm_component_utils(game_occupied_retry_test)
  function new(string name = "game_occupied_retry_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    game_occupied_retry_seq seqh = game_occupied_retry_seq::type_id::create("seqh");
    run_seq_with_drain(phase, seqh);
  endtask
endclass

class game_unused_pins_test extends test;
  `uvm_component_utils(game_unused_pins_test)
  function new(string name = "game_unused_pins_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    game_unused_pins_seq seqh = game_unused_pins_seq::type_id::create("seqh");
    run_seq_with_drain(phase, seqh);
  endtask
endclass

class game_over_test extends test;
  `uvm_component_utils(game_over_test)
  function new(string name = "game_over_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    game_over_seq seqh = game_over_seq::type_id::create("seqh");
    run_seq_with_drain(phase, seqh);
  endtask
endclass

class game_win_glyph_test extends test;
  `uvm_component_utils(game_win_glyph_test)
  function new(string name = "game_win_glyph_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    game_win_glyph_seq seqh = game_win_glyph_seq::type_id::create("seqh");
    seqh.scb_h = envh.scrh;
    run_seq_with_drain(phase, seqh);
  endtask
endclass

class game_random_test extends test;
  `uvm_component_utils(game_random_test)
  function new(string name = "game_random_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    game_random_seq seqh = game_random_seq::type_id::create("seqh");
    if (!seqh.randomize()) `uvm_fatal("TEST", "Randomization of game_random_seq failed")
    run_seq_with_drain(phase, seqh);
  endtask
endclass