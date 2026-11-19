// class test extends uvm_test;
// 	`uvm_component_utils(test)
//     base_sequence seqh;
// 	environment envh;

// 	function new(string name="test",uvm_component parent);
// 		 super.new(name, parent);
// 	endfunction

// 	function void build_phase(uvm_phase phase);
// 		super.build_phase(phase);
// 		envh=environment::type_id::create("envh",this);
// 	endfunction
// 	function void end_of_elaboration_phase(uvm_phase phase);
// 		super.end_of_elaboration_phase(phase);
// 		uvm_top.print_topology();
// 	endfunction

// 	task run_phase(uvm_phase phase);
// 		phase.raise_objection(this);
// 		seqh=base_sequence::type_id::create("seqh");
//         seqh.start(envh.aa.seqrh);
//         phase.drop_objection(this);                         
// 		phase.phase_done.set_drain_time(this, 10); 
// 	endtask
// endclass
 
 // =============================================================================
// Default Test: Runs ALL Sequences (Smoke, Priority, Invalid/Reset, Random,
// Game-Over, and Win/Glyph) Back-to-Back
// =============================================================================
class test extends uvm_test;
    `uvm_component_utils(test)

    full_regression_seq reg_seqh;
    environment         envh;

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

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        phase.phase_done.set_drain_time(this, 100);

        reg_seqh = full_regression_seq::type_id::create("reg_seqh");
        reg_seqh.start(envh.aa.seqrh);

        phase.drop_objection(this);
    endtask
endclass

// =============================================================================
// Individual Targeted Tests (Selectable via +UVM_TESTNAME=<name>)
// =============================================================================
class game_smoke_test extends test;
    `uvm_component_utils(game_smoke_test)
    function new(string name = "game_smoke_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        game_smoke_seq seqh;
        phase.raise_objection(this);
        seqh = game_smoke_seq::type_id::create("seqh");
        seqh.start(envh.aa.seqrh);
        phase.drop_objection(this);
    endtask
endclass

class game_moves_prio_test extends test;
    `uvm_component_utils(game_moves_prio_test)
    function new(string name = "game_moves_prio_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        game_moves_prio_seq seqh;
        phase.raise_objection(this);
        seqh = game_moves_prio_seq::type_id::create("seqh");
        seqh.start(envh.aa.seqrh);
        phase.drop_objection(this);
    endtask
endclass

class game_invalid_and_reset_test extends test;
    `uvm_component_utils(game_invalid_and_reset_test)
    function new(string name = "game_invalid_and_reset_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        game_invalid_and_reset_seq seqh;
        phase.raise_objection(this);
        seqh = game_invalid_and_reset_seq::type_id::create("seqh");
        seqh.start(envh.aa.seqrh);
        phase.drop_objection(this);
    endtask
endclass

class game_random_test extends test;
    `uvm_component_utils(game_random_test)
    function new(string name = "game_random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        game_random_seq seqh;
        phase.raise_objection(this);
        seqh = game_random_seq::type_id::create("seqh");
        assert(seqh.randomize());
        seqh.start(envh.aa.seqrh);
        phase.drop_objection(this);
    endtask
endclass

class game_over_test extends test;
    `uvm_component_utils(game_over_test)
    function new(string name = "game_over_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        game_over_seq seqh;
        phase.raise_objection(this);
        seqh = game_over_seq::type_id::create("seqh");
        seqh.start(envh.aa.seqrh);
        phase.drop_objection(this);
    endtask
endclass

class game_win_glyph_test extends test;
    `uvm_component_utils(game_win_glyph_test)
    function new(string name = "game_win_glyph_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        game_win_glyph_seq seqh;
        phase.raise_objection(this);
        seqh = game_win_glyph_seq::type_id::create("seqh");
        seqh.start(envh.aa.seqrh);
        phase.drop_objection(this);
    endtask
endclass