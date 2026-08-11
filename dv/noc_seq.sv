`ifndef NOC_SEQ_SV
`define NOC_SEQ_SV

class noc_base_seq extends uvm_sequence #(noc_packet);
    `uvm_object_utils(noc_base_seq)

    int unsigned num_packets = 5;

    bit     has_fixed_dest = 0;
    bit [7:0] fixed_dest_x;
    bit [7:0] fixed_dest_y;

    function new (string name = "noc_base_seq");
        super.new(name);
    endfunction

    virtual task body ();
        noc_packet pkt;
        for (int i = 0; i < num_packets; i++) begin
            pkt = noc_packet::type_id::create($sformatf("pkt_%0d", i));
            start_item(pkt);

            if (has_fixed_dest) begin
                if (!pkt.randomize() with {
                    dest_x == fixed_dest_x;
                    dest_y == fixed_dest_y;
                })
                    `uvm_error("SEQ", "Directed randomization failed")
            end else begin
                if (!pkt.randomize())
                    `uvm_error("SEQ", "Randomization failed")
            end
            finish_item(pkt);
        end
    endtask
endclass

`endif