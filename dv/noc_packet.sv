`ifndef NOC_PACKET_SV
`define NOC_PACKET_SV

class noc_packet extends uvm_sequence_item;

    // packet fields matching rtl
    rand bit [7:0]  dest_x;
    rand bit [7:0]  dest_y;
    rand bit [15:0] payload;

    // not randomized - stamped by driver (source) or monitor (observed port)
    int unsigned port_id;

    `uvm_object_utils_begin(noc_packet)
        `uvm_field_int(dest_x,   UVM_ALL_ON)
        `uvm_field_int(dest_y,   UVM_ALL_ON)
        `uvm_field_int(payload,  UVM_ALL_ON)
        `uvm_field_int(port_id,  UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_object_utils_end

    // constraints to ensure traffic stays within mesh
    constraint valid_coords {
        dest_x < 4;
        dest_y < 4;
    }

    function new(string name = "noc_packet");
        super.new(name);
    endfunction

    // pack fields into 32-bit, matches input_port's fifo_dout[31:24]=X, [23:16]=Y
    function bit [31:0] get_full_packet();
        return {dest_x, dest_y, payload};
    endfunction

    // unpack a captured 32-bit word back into fields (used by monitor)
    function void unpack_from_word(bit [31:0] data);
        dest_x  = data[31:24];
        dest_y  = data[23:16];
        payload = data[15:0];
    endfunction

endclass

`endif
