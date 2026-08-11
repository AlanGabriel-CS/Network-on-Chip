`ifndef NOC_TEST_SV
`define NOC_TEST_SV

class noc_test extends uvm_test;
    `uvm_component_utils(noc_test)

    noc_env env;

    function new(string name = "noc_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = noc_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);

        // ---- Phase 1: baseline random traffic on every port ----
        fork
            begin
                noc_base_seq s0 = noc_base_seq::type_id::create("rand_seq_0");
                s0.num_packets = 5;
                s0.start(env.agents[0].sequencer);
            end
            begin
                noc_base_seq s1 = noc_base_seq::type_id::create("rand_seq_1");
                s1.num_packets = 5;
                s1.start(env.agents[1].sequencer);
            end
            begin
                noc_base_seq s2 = noc_base_seq::type_id::create("rand_seq_2");
                s2.num_packets = 5;
                s2.start(env.agents[2].sequencer);
            end
            begin
                noc_base_seq s3 = noc_base_seq::type_id::create("rand_seq_3");
                s3.num_packets = 5;
                s3.start(env.agents[3].sequencer);
            end
            begin
                noc_base_seq s4 = noc_base_seq::type_id::create("rand_seq_4");
                s4.num_packets = 5;
                s4.start(env.agents[4].sequencer);
            end
        join

        #100;

        // ---- Phase 2: directed collision ----
        // Ports 0-3 all target this router's own (0,0) coordinate at the
        // same time, all routing to the Local output (port 4) simultaneously
        // - forces real 4-way arbiter contention on one output.
        fork
            begin
                noc_base_seq c0 = noc_base_seq::type_id::create("collision_seq_0");
                c0.num_packets = 3;
                c0.has_fixed_dest = 1;
                c0.fixed_dest_x = 0;
                c0.fixed_dest_y = 0;
                c0.start(env.agents[0].sequencer);
            end
            begin
                noc_base_seq c1 = noc_base_seq::type_id::create("collision_seq_1");
                c1.num_packets = 3;
                c1.has_fixed_dest = 1;
                c1.fixed_dest_x = 0;
                c1.fixed_dest_y = 0;
                c1.start(env.agents[1].sequencer);
            end
            begin
                noc_base_seq c2 = noc_base_seq::type_id::create("collision_seq_2");
                c2.num_packets = 3;
                c2.has_fixed_dest = 1;
                c2.fixed_dest_x = 0;
                c2.fixed_dest_y = 0;
                c2.start(env.agents[2].sequencer);
            end
            begin
                noc_base_seq c3 = noc_base_seq::type_id::create("collision_seq_3");
                c3.num_packets = 3;
                c3.has_fixed_dest = 1;
                c3.fixed_dest_x = 0;
                c3.fixed_dest_y = 0;
                c3.start(env.agents[3].sequencer);
            end
        join

        #200;

        // ---- Phase 3: boundary address ----
        // Max-valid mesh coordinate (3,3), per noc_packet's valid_coords
        // constraint (dest_x < 4, dest_y < 4).
        begin
            noc_base_seq boundary_seq = noc_base_seq::type_id::create("boundary_seq");
            boundary_seq.num_packets = 2;
            boundary_seq.has_fixed_dest = 1;
            boundary_seq.fixed_dest_x = 3;
            boundary_seq.fixed_dest_y = 3;
            boundary_seq.start(env.agents[4].sequencer);
        end

        #100;

        // ---- Phase 4: hit the arbiter's missing grant_rot[3] branch ----
        // coverage flagged this line as never hit. ptr is unpredictable
        // after phases 1-3 so first send a lone request from port 0 to
        // force ptr to a known value (1), then a lone request from port 4
        // lands on req_rot[3] exactly
        #300; // drain first

        begin
            noc_base_seq calib_seq = noc_base_seq::type_id::create("arb_calib_seq");
            calib_seq.num_packets = 1;
            calib_seq.has_fixed_dest = 1;
            calib_seq.fixed_dest_x = 0;
            calib_seq.fixed_dest_y = 0;
            calib_seq.start(env.agents[0].sequencer);
        end

        #100; // let it clear the arbiter

        begin
            noc_base_seq arb_target_seq = noc_base_seq::type_id::create("arb_rot3_seq");
            arb_target_seq.num_packets = 1;
            arb_target_seq.has_fixed_dest = 1;
            arb_target_seq.fixed_dest_x = 0;
            arb_target_seq.fixed_dest_y = 0;
            arb_target_seq.start(env.agents[4].sequencer);
        end

        #100;
        // ---- Phase 5: full 5-way collision ----
        // phase 2 only used agents 0-3 so max contention on output 4
        // was 4-way. adding agent 4 here to actually hit 5/5.
        #300; // drain first

        fork
            begin
                noc_base_seq f0 = noc_base_seq::type_id::create("fiveway_seq_0");
                f0.num_packets = 2;
                f0.has_fixed_dest = 1;
                f0.fixed_dest_x = 0;
                f0.fixed_dest_y = 0;
                f0.start(env.agents[0].sequencer);
            end
            begin
                noc_base_seq f1 = noc_base_seq::type_id::create("fiveway_seq_1");
                f1.num_packets = 2;
                f1.has_fixed_dest = 1;
                f1.fixed_dest_x = 0;
                f1.fixed_dest_y = 0;
                f1.start(env.agents[1].sequencer);
            end
            begin
                noc_base_seq f2 = noc_base_seq::type_id::create("fiveway_seq_2");
                f2.num_packets = 2;
                f2.has_fixed_dest = 1;
                f2.fixed_dest_x = 0;
                f2.fixed_dest_y = 0;
                f2.start(env.agents[2].sequencer);
            end
            begin
                noc_base_seq f3 = noc_base_seq::type_id::create("fiveway_seq_3");
                f3.num_packets = 2;
                f3.has_fixed_dest = 1;
                f3.fixed_dest_x = 0;
                f3.fixed_dest_y = 0;
                f3.start(env.agents[3].sequencer);
            end
            begin
                noc_base_seq f4 = noc_base_seq::type_id::create("fiveway_seq_4");
                f4.num_packets = 2;
                f4.has_fixed_dest = 1;
                f4.fixed_dest_x = 0;
                f4.fixed_dest_y = 0;
                f4.start(env.agents[4].sequencer);
            end
        join

        #200;

        // ---- Phase 6: dest coord sweep ----
        // hits every (x,y) dest from every port to close the gaps
        // phase 1's random traffic left (only ~25/80 combos by luck)
        #300;

        fork
            begin : sweep_port0
                for (int x = 0; x < 4; x++) begin
                    for (int y = 0; y < 4; y++) begin
                        noc_base_seq sw = noc_base_seq::type_id::create($sformatf("sweep_p0_x%0d_y%0d", x, y));
                        sw.num_packets = 1;
                        sw.has_fixed_dest = 1;
                        sw.fixed_dest_x = x;
                        sw.fixed_dest_y = y;
                        sw.start(env.agents[0].sequencer);
                    end
                end
            end
            begin : sweep_port1
                for (int x = 0; x < 4; x++) begin
                    for (int y = 0; y < 4; y++) begin
                        noc_base_seq sw = noc_base_seq::type_id::create($sformatf("sweep_p1_x%0d_y%0d", x, y));
                        sw.num_packets = 1;
                        sw.has_fixed_dest = 1;
                        sw.fixed_dest_x = x;
                        sw.fixed_dest_y = y;
                        sw.start(env.agents[1].sequencer);
                    end
                end
            end
            begin : sweep_port2
                for (int x = 0; x < 4; x++) begin
                    for (int y = 0; y < 4; y++) begin
                        noc_base_seq sw = noc_base_seq::type_id::create($sformatf("sweep_p2_x%0d_y%0d", x, y));
                        sw.num_packets = 1;
                        sw.has_fixed_dest = 1;
                        sw.fixed_dest_x = x;
                        sw.fixed_dest_y = y;
                        sw.start(env.agents[2].sequencer);
                    end
                end
            end
            begin : sweep_port3
                for (int x = 0; x < 4; x++) begin
                    for (int y = 0; y < 4; y++) begin
                        noc_base_seq sw = noc_base_seq::type_id::create($sformatf("sweep_p3_x%0d_y%0d", x, y));
                        sw.num_packets = 1;
                        sw.has_fixed_dest = 1;
                        sw.fixed_dest_x = x;
                        sw.fixed_dest_y = y;
                        sw.start(env.agents[3].sequencer);
                    end
                end
            end
            begin : sweep_port4
                for (int x = 0; x < 4; x++) begin
                    for (int y = 0; y < 4; y++) begin
                        noc_base_seq sw = noc_base_seq::type_id::create($sformatf("sweep_p4_x%0d_y%0d", x, y));
                        sw.num_packets = 1;
                        sw.has_fixed_dest = 1;
                        sw.fixed_dest_x = x;
                        sw.fixed_dest_y = y;
                        sw.start(env.agents[4].sequencer);
                    end
                end
            end
        join

        #300;

        // ---- Phase 7: North output contention ----
        // same idea as phase 5 but for output 1 (North), and ramping
        // 2->3->4->5-way instead of jumping straight to max
        #200;
        fork
            begin
                noc_base_seq n2_0 = noc_base_seq::type_id::create("north2_seq_0");
                n2_0.num_packets = 1; n2_0.has_fixed_dest = 1; n2_0.fixed_dest_x = 0; n2_0.fixed_dest_y = 3;
                n2_0.start(env.agents[0].sequencer);
            end
            begin
                noc_base_seq n2_1 = noc_base_seq::type_id::create("north2_seq_1");
                n2_1.num_packets = 1; n2_1.has_fixed_dest = 1; n2_1.fixed_dest_x = 0; n2_1.fixed_dest_y = 3;
                n2_1.start(env.agents[1].sequencer);
            end
        join
        #150;

        fork
            begin
                noc_base_seq n3_0 = noc_base_seq::type_id::create("north3_seq_0");
                n3_0.num_packets = 1; n3_0.has_fixed_dest = 1; n3_0.fixed_dest_x = 0; n3_0.fixed_dest_y = 3;
                n3_0.start(env.agents[0].sequencer);
            end
            begin
                noc_base_seq n3_1 = noc_base_seq::type_id::create("north3_seq_1");
                n3_1.num_packets = 1; n3_1.has_fixed_dest = 1; n3_1.fixed_dest_x = 0; n3_1.fixed_dest_y = 3;
                n3_1.start(env.agents[1].sequencer);
            end
            begin
                noc_base_seq n3_2 = noc_base_seq::type_id::create("north3_seq_2");
                n3_2.num_packets = 1; n3_2.has_fixed_dest = 1; n3_2.fixed_dest_x = 0; n3_2.fixed_dest_y = 3;
                n3_2.start(env.agents[2].sequencer);
            end
        join
        #150;

        fork
            begin
                noc_base_seq n4_0 = noc_base_seq::type_id::create("north4_seq_0");
                n4_0.num_packets = 1; n4_0.has_fixed_dest = 1; n4_0.fixed_dest_x = 0; n4_0.fixed_dest_y = 3;
                n4_0.start(env.agents[0].sequencer);
            end
            begin
                noc_base_seq n4_1 = noc_base_seq::type_id::create("north4_seq_1");
                n4_1.num_packets = 1; n4_1.has_fixed_dest = 1; n4_1.fixed_dest_x = 0; n4_1.fixed_dest_y = 3;
                n4_1.start(env.agents[1].sequencer);
            end
            begin
                noc_base_seq n4_2 = noc_base_seq::type_id::create("north4_seq_2");
                n4_2.num_packets = 1; n4_2.has_fixed_dest = 1; n4_2.fixed_dest_x = 0; n4_2.fixed_dest_y = 3;
                n4_2.start(env.agents[2].sequencer);
            end
            begin
                noc_base_seq n4_3 = noc_base_seq::type_id::create("north4_seq_3");
                n4_3.num_packets = 1; n4_3.has_fixed_dest = 1; n4_3.fixed_dest_x = 0; n4_3.fixed_dest_y = 3;
                n4_3.start(env.agents[3].sequencer);
            end
        join
        #150;

        fork
            begin
                noc_base_seq n5_0 = noc_base_seq::type_id::create("north5_seq_0");
                n5_0.num_packets = 1; n5_0.has_fixed_dest = 1; n5_0.fixed_dest_x = 0; n5_0.fixed_dest_y = 3;
                n5_0.start(env.agents[0].sequencer);
            end
            begin
                noc_base_seq n5_1 = noc_base_seq::type_id::create("north5_seq_1");
                n5_1.num_packets = 1; n5_1.has_fixed_dest = 1; n5_1.fixed_dest_x = 0; n5_1.fixed_dest_y = 3;
                n5_1.start(env.agents[1].sequencer);
            end
            begin
                noc_base_seq n5_2 = noc_base_seq::type_id::create("north5_seq_2");
                n5_2.num_packets = 1; n5_2.has_fixed_dest = 1; n5_2.fixed_dest_x = 0; n5_2.fixed_dest_y = 3;
                n5_2.start(env.agents[2].sequencer);
            end
            begin
                noc_base_seq n5_3 = noc_base_seq::type_id::create("north5_seq_3");
                n5_3.num_packets = 1; n5_3.has_fixed_dest = 1; n5_3.fixed_dest_x = 0; n5_3.fixed_dest_y = 3;
                n5_3.start(env.agents[3].sequencer);
            end
            begin
                noc_base_seq n5_4 = noc_base_seq::type_id::create("north5_seq_4");
                n5_4.num_packets = 1; n5_4.has_fixed_dest = 1; n5_4.fixed_dest_x = 0; n5_4.fixed_dest_y = 3;
                n5_4.start(env.agents[4].sequencer);
            end
        join
        #200;

        phase.drop_objection(this);
    endtask
endclass

`endif
