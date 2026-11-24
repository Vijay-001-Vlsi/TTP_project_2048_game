class driver extends uvm_driver #(seq_item);
    `uvm_component_utils(driver)
    virtual game_2048_inf.DRV vif;

    function new(string name = "driver", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual game_2048_inf.DRV)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "Virtual interface not found")
    endfunction

    task run_phase(uvm_phase phase);
        // Initialize outputs during reset
        vif.drv.ui_in  <= '0;
        vif.drv.uio_in <= '0;
        vif.drv.ena    <= 1'b1;

        // Wait for hard reset to complete
        wait(vif.rst_n == 1'b0);
        wait(vif.rst_n == 1'b1);
        @(vif.drv);

        forever begin
            seq_item_port.get_next_item(req);
            drv(req);
            seq_item_port.item_done();
        end
    endtask

    task drv(seq_item req);
        @(negedge vif.drv.uo_out[3]);
        @(vif.drv);
        vif.drv.ui_in  <= req.ui_in;
        vif.drv.uio_in <= req.uio_in;
        vif.drv.ena    <= req.ena;
        `uvm_info(get_type_name(), $sformatf("Driven transaction: ui_in=0x%0h, uio_in=0x%0h, ena=%0b",
                  req.ui_in, req.uio_in, req.ena), UVM_LOW)

        repeat (3) @(negedge vif.drv.uo_out[3]);
        @(vif.drv);
        vif.drv.ui_in <= 8'h00;

        repeat (3) @(negedge vif.drv.uo_out[3]);
    endtask
endclass
