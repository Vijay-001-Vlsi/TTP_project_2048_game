class passive_agent extends uvm_agent;
        `uvm_component_utils(passive_agent)
	uvm_analysis_port #(seq_item)ap;
        driver drvh;
        game2048_out_monitor monh;
        sequencer seqrh;
        function new(string name="passive_agent",uvm_component parent);
                super.new(name,parent);
                ap=new("passive_agent_analysis_port",this);
        endfunction

        function void build_phase(uvm_phase phase);
                super.build_phase(phase);
                monh=game2048_out_monitor::type_id::create("monh",this);
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