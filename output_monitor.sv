class game2048_out_monitor extends uvm_monitor;
    virtual game_2048_inf.MON vif;
    `uvm_component_utils(game2048_out_monitor)
    uvm_analysis_port #(seq_item) ap;

    bit       prev_vsync = 1'b1;
    int       frame_cnt  = 0;
    int       active_px  = 0;

    function new(string name = "game2048_out_monitor", uvm_component parent);
        super.new(name, parent);
        ap = new("output_monitor_analysis_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual game_2048_inf.MON)::get(this, "", "vif", vif))
            `uvm_fatal("OUTPUT_MON", "Virtual interface not found")
    endfunction

    task run_phase(uvm_phase phase);
        seq_item req;
        bit cur_vsync;
        bit [5:0] rgb_bits;

        @(vif.mon);
        forever begin
            @(vif.mon);
            req = seq_item::type_id::create("output_txn");
            req.uo_out  = vif.mon.uo_out;
            req.uio_out = vif.mon.uio_out;
            req.uio_oe  = vif.mon.uio_oe;

            cur_vsync = req.uo_out[3];
            rgb_bits  = {req.uo_out[0], req.uo_out[1], req.uo_out[2],
                         req.uo_out[4], req.uo_out[5], req.uo_out[6]};

            if (rgb_bits != 6'b0)
                active_px++;

            // Print once per VGA frame on VSYNC falling edge so you verify DUT activity cleanly
            if (prev_vsync == 1'b1 && cur_vsync == 1'b0) begin
                `uvm_info(get_type_name(),
                          $sformatf("Frame %0d VSYNC | non-zero RGB clocks=%0d | last uo_out=0x%0h, uio_out=0x%0h, uio_oe=0x%0h",
                                    frame_cnt, active_px, req.uo_out, req.uio_out, req.uio_oe),
                          UVM_LOW)
                frame_cnt++;
                active_px = 0;
            end
            prev_vsync = cur_vsync;

            // Still send every clock sample to the scoreboard
            ap.write(req);
        end
    endtask
endclass