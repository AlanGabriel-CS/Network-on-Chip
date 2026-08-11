module arbiter (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [4:0] request,
    output logic [4:0] grant
);

    logic [4:0] next_grant;
    logic [2:0] ptr;        // who's turn it is for top priority
    logic [4:0] req_rot;    // request rotated so ptr lines up with bit 0
    logic [4:0] grant_rot;

    // rotate so the current priority pointer sits at bit 0
    always_comb begin
        int idx;
        for (int k = 0; k < 5; k++) begin
            idx = (k + int'(ptr)) % 5;
            req_rot[k] = request[idx];
        end
    end

    // lowest index wins on the rotated vector - since bit 0 is always
    // whoever's turn it is, this gives round robin instead of port 0
    // winning every tie like the old version did
    always_comb begin
        grant_rot = 5'b00000;
        if      (req_rot[0]) grant_rot = 5'b00001;
        else if (req_rot[1]) grant_rot = 5'b00010;
        else if (req_rot[2]) grant_rot = 5'b00100;
        else if (req_rot[3]) grant_rot = 5'b01000;
        else if (req_rot[4]) grant_rot = 5'b10000;
    end

    // rotate the winner back to its real position
    always_comb begin
        int idx;
        next_grant = 5'b00000;
        for (int k = 0; k < 5; k++) begin
            idx = (k + int'(ptr)) % 5;
            if (grant_rot[k]) next_grant[idx] = 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ptr   <= 3'd0;
            grant <= 5'b00000;
        end else begin
            grant <= next_grant;
            // move ptr to whoever's after the winner so they get priority next cycle
            for (int k = 0; k < 5; k++)
                if (next_grant[k]) ptr <= 3'(unsigned'((k + 1) % 5));
        end
    end
endmodule