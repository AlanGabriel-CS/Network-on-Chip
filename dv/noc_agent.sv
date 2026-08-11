`ifndef NOC_AGENT_SV
`define NOC_AGENT_SV

class noc_agent extends uvm_agent;
    `uvm_component_utils(noc_agent)

    noc_driver driver;
    noc_monitor monitor;
    uvm_sequencer #(noc_packet) sequencer;
    int unsigned port_id;

    function new(string name = "noc_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(int)::get(this, "", "port_id", port_id))
            `uvm_fatal("AGT", "port_id not set for agent")

        // propagate port_id down to children explicitly (belt-and-braces,
        // env already sets it on the wildcard path too)
        uvm_config_db#(int)::set(this, "driver",  "port_id", port_id);
        uvm_config_db#(int)::set(this, "monitor", "port_id", port_id);

        sequencer = uvm_sequencer#(noc_packet)::type_id::create("sequencer", this);
        driver    = noc_driver::type_id::create("driver", this);
        monitor   = noc_monitor::type_id::create("monitor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass

`endif
