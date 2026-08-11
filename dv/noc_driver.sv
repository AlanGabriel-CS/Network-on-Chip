`ifndef NOC_DRIVER_SV
`define NOC_DRIVER_SV

class noc_driver extends uvm_driver #(noc_packet);
    `uvm_component_utils(noc_driver)

    virtual noc_if vif;
    int unsigned port_id;

    function new(string name = "noc_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(int)::get(this, "", "port_id", port_id))
            `uvm_fatal("DRV", "port_id not set for driver")
        if (!uvm_config_db#(virtual noc_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", $sformatf("could not get virtual interface for port %0d", port_id))
    endfunction

    virtual task run_phase(uvm_phase phase);
        vif.s_tvalid <= 1'b0;
        vif.s_tdata  <= '0;

        // hold off until reset deasserts
        @(posedge vif.rst_n);

        forever begin
            noc_packet pkt;
            seq_item_port.get_next_item(pkt);
            pkt.port_id = port_id;

            @(posedge vif.clk);
            vif.s_tdata  <= pkt.get_full_packet();
            vif.s_tvalid <= 1'b1;

            // synchronous wait for handshake (avoid zero-time races)
            do begin
                @(posedge vif.clk);
            end while (!vif.s_tready);

            vif.s_tvalid <= 1'b0;

            `uvm_info("DRV", $sformatf("Port %0d drove packet: X=%0d Y=%0d payload=0x%h",
                       port_id, pkt.dest_x, pkt.dest_y, pkt.payload), UVM_MEDIUM)

            seq_item_port.item_done();
        end
    endtask
endclass

`endif
