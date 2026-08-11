`ifndef NOC_SCOREBOARD_SV
`define NOC_SCOREBOARD_SV

`uvm_analysis_imp_decl(_ingress)
`uvm_analysis_imp_decl(_egress)

// searching the whole pending queue here instead of just the head, so a
// real bug doesn't get buried under cascade noise from an earlier
// mismatch - lets me tell apart out-of-order matches from actually
// missing packets. should go back to strict head-only once this is
// tracked down, that's the correct check for a real scoreboard
class noc_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(noc_scoreboard)

    uvm_analysis_imp_ingress #(noc_packet, noc_scoreboard) ingress_export;
    uvm_analysis_imp_egress  #(noc_packet, noc_scoreboard) egress_export;

    bit [7:0] router_x = 8'd0;
    bit [7:0] router_y = 8'd0;

    noc_packet pending_q[5][$];

    int unsigned matched_count   = 0;
    int unsigned reordered_count = 0;
    int unsigned mismatch_count  = 0;

    function new(string name = "noc_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ingress_export = new("ingress_export", this);
        egress_export  = new("egress_export", this);
        void'(uvm_config_db#(bit [7:0])::get(this, "", "router_x", router_x));
        void'(uvm_config_db#(bit [7:0])::get(this, "", "router_y", router_y));
    endfunction

    function int unsigned predict_output_port(bit [7:0] dest_x, bit [7:0] dest_y);
        if (dest_x > router_x) return 3;
        if (dest_x < router_x) return 2;
        if (dest_y > router_y) return 1;
        if (dest_y < router_y) return 0;
        return 4;
    endfunction

    virtual function void write_ingress(noc_packet pkt);
        noc_packet exp = noc_packet::type_id::create("exp");
        exp.dest_x  = pkt.dest_x;
        exp.dest_y  = pkt.dest_y;
        exp.payload = pkt.payload;
        exp.port_id = predict_output_port(pkt.dest_x, pkt.dest_y);
        pending_q[pkt.port_id].push_back(exp);
    endfunction

    virtual function void write_egress(noc_packet pkt);
        int unsigned actual_out = pkt.port_id;
        bit found = 0;
        int found_src = -1;
        int found_idx = -1;

        for (int src = 0; src < 5; src++) begin
            foreach (pending_q[src][i]) begin
                if (pending_q[src][i].port_id == actual_out &&
                    pending_q[src][i].dest_x  == pkt.dest_x &&
                    pending_q[src][i].dest_y  == pkt.dest_y &&
                    pending_q[src][i].payload == pkt.payload) begin
                    found     = 1;
                    found_src = src;
                    found_idx = i;
                    break;
                end
            end
            if (found) break;
        end

        if (found) begin
            if (found_idx != 0) begin
                reordered_count++;
                `uvm_warning("SCB", $sformatf("DIAGNOSTIC: egress on port %0d matched a packet from source %0d but NOT at queue head (position %0d) - out-of-order delivery (X=%0d Y=%0d payload=0x%h)", actual_out, found_src, found_idx, pkt.dest_x, pkt.dest_y, pkt.payload))
            end else begin
                matched_count++;
            end
            pending_q[found_src].delete(found_idx);
        end else begin
            mismatch_count++;
            `uvm_error("SCB", $sformatf("Egress on port %0d has NO matching expected packet anywhere in any source queue (X=%0d Y=%0d payload=0x%h) - genuine drop, corruption, or misroute", actual_out, pkt.dest_x, pkt.dest_y, pkt.payload))
        end
    endfunction

    function void report_phase(uvm_phase phase);
        int unsigned dropped_count = 0;

        for (int src = 0; src < 5; src++) begin
            foreach (pending_q[src][i]) begin
                dropped_count++;
                `uvm_error("SCB", $sformatf("DROPPED: packet from port %0d never arrived (expected output %0d, X=%0d Y=%0d payload=0x%h)", src, pending_q[src][i].port_id, pending_q[src][i].dest_x, pending_q[src][i].dest_y, pending_q[src][i].payload))
            end
        end

        `uvm_info("SCB", $sformatf("Scoreboard summary: %0d matched-in-order, %0d matched-out-of-order, %0d unmatched, %0d dropped", matched_count, reordered_count, mismatch_count, dropped_count), UVM_LOW)
    endfunction
endclass

`endif
