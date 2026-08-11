// arbiter_sva.sv
// bind-in checker for arbiter.sv
//   - grant is always one-hot or zero (never double-grants)
//   - grant can only be set for a requester that asked for it the cycle
//     before (grant is registered, next_grant is combinational off request)
//   - ptr only moves when a grant was actually issued, holds otherwise -
//     protects the round-robin fairness the arbiter fix relied on
//   - grant is zero until reset deasserts
//
// kept every property to single-cycle |-> since deeper sequences are
// where verilator's SVA support tends to have gaps

module arbiter_sva (
    input logic       clk,
    input logic       rst_n,
    input logic [4:0] request,
    input logic [4:0] grant,
    input logic [2:0] ptr,
    input logic [4:0] next_grant
);

    // grant one-hot or zero, every cycle
    a_grant_onehot0: assert property (
        @(posedge clk) $onehot0(grant)
    ) else $error("[ARB_SVA] grant is not one-hot0: %b", grant);

    // can't grant a phantom request - grant bit must trace back to
    // something that actually requested last cycle
    a_grant_implies_past_request: assert property (
        @(posedge clk) disable iff (!rst_n)
        (grant != 5'b0) |-> ((grant & $past(request)) == grant)
    ) else $error("[ARB_SVA] grant %b not covered by previous request %b",
                   grant, $past(request));

    // no request last cycle -> no grant this cycle
    a_no_request_no_grant: assert property (
        @(posedge clk) disable iff (!rst_n)
        ($past(request) == 5'b0) |-> (grant == 5'b0)
    ) else $error("[ARB_SVA] grant %b issued with no prior request", grant);

    // ptr shouldn't drift if nobody won last round
    a_ptr_holds_on_no_grant: assert property (
        @(posedge clk) disable iff (!rst_n)
        (next_grant == 5'b0) |=> (ptr == $past(ptr))
    ) else $error("[ARB_SVA] ptr moved (%0d -> %0d) across a cycle where next_grant was 0",
                   $past(ptr), ptr);

    // grant forced zero during reset
    a_reset_clears_grant: assert property (
        @(posedge clk) !rst_n |-> (grant == 5'b0)
    ) else $error("[ARB_SVA] grant not zero while in reset: %b", grant);

endmodule

bind arbiter arbiter_sva u_arbiter_sva (
    .clk        (clk),
    .rst_n      (rst_n),
    .request    (request),
    .grant      (grant),
    .ptr        (ptr),
    .next_grant (next_grant)
);
