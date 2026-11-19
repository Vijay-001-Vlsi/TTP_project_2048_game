class game2048_inp_monitor extends uvm_monitor;
    virtual game_2048_inf.MON vif;
    `uvm_component_utils(game2048_inp_monitor)
    uvm_analysis_port #(seq_item) ap;

    bit [7:0] prev_ui_in  = 8'hFF;
    bit [7:0] prev_uio_in = 8'hFF;
    bit       prev_ena    = 1'b0;

    function new(string name = "game2048_inp_monitor", uvm_component parent);
        super.new(name, parent);
        ap = new("input_monitor_analysis_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual game_2048_inf.MON)::get(this, "", "vif", vif))
            `uvm_fatal("INPUT_MON", "Virtual interface not found")
    endfunction

    task run_phase(uvm_phase phase);
        seq_item req;
        @(vif.mon);
        forever begin
            @(vif.mon);
            req = seq_item::type_id::create("input_txn");
            req.ui_in  = vif.mon.ui_in;
            req.uio_in = vif.mon.uio_in;
            req.ena    = vif.mon.ena;

            // Print only when inputs change to avoid millions of log lines
            if (req.ui_in != prev_ui_in || req.uio_in != prev_uio_in || req.ena != prev_ena) begin
                `uvm_info(get_type_name(), $sformatf("Input changed: ui_in=0x%0h, uio_in=0x%0h, ena=%0b",
                          req.ui_in, req.uio_in, req.ena), UVM_LOW)
                prev_ui_in  = req.ui_in;
                prev_uio_in = req.uio_in;
                prev_ena    = req.ena;
            end
            ap.write(req);
        end
    endtask
endclass