// router_top_sva.sv
// bound into router_top to lock down the grant/request race bug i found
// from waveform traces - grant_matrix[j] is registered (one cycle stale)
// vs the requester's current fifo head, fix was requalifying it against
// request_vec before it drives the crossbar (eff_grant_matrix). these
// assertions should catch it immediately if that ever regresses instead
// of needing another waveform hunt.
//
// a_no_stale_grant is the actual regression guard for the bug, the rest
// are general grant/crossbar legality checks.
//
// plain assert property + bind instead of a checker block since
// verilator's checker support is spottier

module router_top_sva (
    input logic       clk,
    input logic       rst_n,
    input logic [4:0] request_vec       [5],
    input logic [4:0] grant_matrix      [5],
    input logic [4:0] eff_grant_matrix  [5],
    input logic       m_axis_tvalid     [5]
);

    genvar j, i;
    generate
        for (j = 0; j < 5; j++) begin : gen_out
            a_eff_onehot0: assert property (
                @(posedge clk) disable iff (!rst_n)
                $onehot0(eff_grant_matrix[j])
            ) else $error("[ROUTER_SVA] output %0d: more than one input effectively granted (%b)",
                           j, eff_grant_matrix[j]);

            a_valid_implies_effgrant: assert property (
                @(posedge clk) disable iff (!rst_n)
                m_axis_tvalid[j] |-> (eff_grant_matrix[j] != 5'b0)
            ) else $error("[ROUTER_SVA] output %0d: tvalid high with no qualified grant", j);

            for (i = 0; i < 5; i++) begin : gen_in
                // the actual regression guard for the race bug
                a_no_stale_grant: assert property (
                    @(posedge clk) disable iff (!rst_n)
                    (grant_matrix[j][i] && !request_vec[i][j]) |-> !eff_grant_matrix[j][i]
                ) else $error("[ROUTER_SVA] STALE GRANT REGRESSION: output %0d granted to input %0d but input %0d no longer requests output %0d this cycle",
                               j, i, i, j);

                a_eff_implies_live_request: assert property (
                    @(posedge clk) disable iff (!rst_n)
                    eff_grant_matrix[j][i] |-> request_vec[i][j]
                ) else $error("[ROUTER_SVA] output %0d: input %0d effectively granted without live request",
                               j, i);
            end
        end
    endgenerate

endmodule

bind router_top router_top_sva u_router_top_sva (
    .clk              (clk),
    .rst_n            (rst_n),
    .request_vec      (request_vec),
    .grant_matrix     (grant_matrix),
    .eff_grant_matrix (eff_grant_matrix),
    .m_axis_tvalid    (m_axis_tvalid)
);
