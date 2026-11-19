class environment extends uvm_env;
	`uvm_component_utils(environment)

	active_agent aa;
	passive_agent pa;

	scoreboard scrh;

	//coverage input_cov;

	function new(string name="environment",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		uvm_config_db #(uvm_active_passive_enum)::set(this,"aa","is_active",UVM_ACTIVE);
		uvm_config_db #(uvm_active_passive_enum)::set(this,"pa","is_active",UVM_PASSIVE);
		aa=active_agent::type_id::create("aa",this);
		pa=passive_agent::type_id::create("pa",this);
		//input_cov=coverage::type_id::create("input_cov",this);
		scrh = scoreboard::type_id::create("scrh", this);
	endfunction

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		aa.ap.connect(scrh.fifo_in.analysis_export);
		pa.ap.connect(scrh.fifo_op.analysis_export);
		//aa.ap.connect(input_cov.analysis_export);
	endfunction
endclass