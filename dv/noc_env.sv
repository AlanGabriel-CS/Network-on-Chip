`ifndef NOC_ENV_SV
`define NOC_ENV_SV

class noc_env extends uvm_env;
    `uvm_component_utils(noc_env)

    localparam int NUM_PORTS = 5;

    noc_agent      agents[NUM_PORTS];
    noc_scoreboard scb;

    function new(string name = "noc_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        scb = noc_scoreboard::type_id::create("scb", this);

        for (int i = 0; i < NUM_PORTS; i++) begin
            string agent_name = $sformatf("agent_%0d", i);
            // must be set BEFORE the agent's build_phase runs
            uvm_config_db#(int)::set(this, agent_name, "port_id", i);
            agents[i] = noc_agent::type_id::create(agent_name, this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        for (int i = 0; i < NUM_PORTS; i++) begin
            agents[i].monitor.ingress_collected_port.connect(scb.ingress_export);
            agents[i].monitor.egress_collected_port.connect(scb.egress_export);
        end
    endfunction
endclass

`endif
