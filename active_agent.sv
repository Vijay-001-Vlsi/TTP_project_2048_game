class active_agent extends uvm_agent;
	`uvm_component_utils(active_agent)
	driver drvh;
	game2048_inp_monitor monh;
	sequencer seqrh;
	uvm_analysis_port #(seq_item)ap;

	function new(string name="active_agent",uvm_component parent);
		super.new(name,parent);
		ap=new("active_agent_analysis_port",this);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		monh=game2048_inp_monitor::type_id::create("monh",this);
		if(get_is_active()==UVM_ACTIVE)begin
			drvh=driver::type_id::create("drvh",this);
			seqrh=sequencer::type_id::create("seqrh",this);
		end
	endfunction

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		monh.ap.connect(ap);
		if(get_is_active()==UVM_ACTIVE)
			drvh.seq_item_port.connect(seqrh.seq_item_export);
	endfunction
endclass