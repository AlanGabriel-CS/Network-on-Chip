// crossbar_sva.sv
// bind-in checker for crossbar.sv. it's purely combinational so these
// are immediate assertions in an always_comb rather than clocked
// properties - verilator's concurrent assertions need a clocking event
// and crossbar doesn't have one of its own
//
// checks that a one-hot grant_matrix[i] actually routes data_in[k] to
// data_out[i] (catches an off-by-one in the port mapping), and that a
// non-one-hot select falls back to zero instead of driving garbage

module crossbar_sva #(
    parameter DATA_WIDTH = 32,
    parameter NUM_PORTS  = 5
)(
    input logic [DATA_WIDTH-1:0] data_in      [NUM_PORTS],
    input logic [NUM_PORTS-1:0]  grant_matrix [NUM_PORTS],
    input logic [DATA_WIDTH-1:0] data_out     [NUM_PORTS]
);

    always_comb begin
        for (int i = 0; i < NUM_PORTS; i++) begin
            if ($onehot(grant_matrix[i])) begin
                for (int k = 0; k < NUM_PORTS; k++) begin
                    if (grant_matrix[i][k]) begin
                        a_output_matches_selected_input: assert (data_out[i] == data_in[k])
                        else $error("[XBAR_SVA] output %0d: grant selects input %0d but data_out != data_in[%0d]",
                                    i, k, k);
                    end
                end
            end else begin
                a_default_on_illegal_select: assert (data_out[i] == '0)
                else $error("[XBAR_SVA] output %0d: grant_matrix not one-hot (%b) but data_out not zeroed",
                            i, grant_matrix[i]);
            end
        end
    end

endmodule

bind crossbar crossbar_sva #(.DATA_WIDTH(DATA_WIDTH), .NUM_PORTS(NUM_PORTS)) u_crossbar_sva (
    .data_in      (data_in),
    .grant_matrix (grant_matrix),
    .data_out     (data_out)
);
