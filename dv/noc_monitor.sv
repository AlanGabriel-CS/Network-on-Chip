`ifndef NOC_MONITOR_SV
`define NOC_MONITOR_SV

class noc_monitor extends uvm_monitor;
    `uvm_component_utils(noc_monitor)

    virtual noc_if vif;
    int unsigned port_id;

    // egress - dut emits on output port
    uvm_analysis_port #(noc_packet) egress_collected_port;

    // ingress - what's accepted into port's input FIFO
    // source side - independent of driver since real handshake on interface
    // driver reported what it thinks it sent
    uvm_analysis_port #(noc_packet) ingress_collected_port;

    function new(string name = "noc_monitor", uvm_component parent = null);
        super.new(name, parent);
        egress_collected_port = new("egress_collected_port", this);
        ingress_collected_port = new("ingress_collected_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(int)::get(this, "", "port_id", port_id))
            `uvm_fatal("MON", "port_id not set for monitor")
        if (!uvm_config_db#(virtual noc_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", $sformatf("coudl not get virtual interface for port %0d", port_id))
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            @(negedge vif.clk);

            // ingress handshake - port own input fifo accepted word this cycle
            if (vif.s_tvalid && vif.s_tready) begin
                noc_packet pkt = noc_packet::type_id::create("pkt");
                pkt.unpack_from_word(vif.s_tdata);
                pkt.port_id = port_id;

                `uvm_info("MON", $sformatf("Port %0d observed ingress packet: X=%0d Y=%0d payload=0x%h",
                           port_id, pkt.dest_x, pkt.dest_y, pkt.payload), UVM_HIGH)

                ingress_collected_port.write(pkt);

            end

            // egress handshake - dut presents packet on output port
            if (vif.m_tvalid && vif.m_tready) begin
                noc_packet pkt = noc_packet::type_id::create("pkt");
                pkt.unpack_from_word(vif.m_tdata);
                pkt.port_id = port_id;

                `uvm_info("MON", $sformatf("port %0d observed egress packet: X=%0d Y=%0d payload=0x%h",
                            port_id, pkt.dest_x, pkt.dest_y, pkt.payload), UVM_MEDIUM)

                egress_collected_port.write(pkt);
            end
        end
    endtask
endclass

`endif
