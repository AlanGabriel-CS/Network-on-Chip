#include "Vrouter_top.h"
#include "verilated.h"
#include <iostream>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vrouter_top* top = new Vrouter_top;

    top->clk = 0;
    top->rst_n = 0;
    for (int i = 0; i < 5; i++) {
        top->s_axis_tdata[i] = 0;
        top->s_axis_tvalid[i] = 0;
        top->m_axis_tready[i] = 0;   // nobody ready yet - hold backpressure
    }

    for (int i = 0; i < 6; i++) { top->clk = !top->clk; top->eval(); }
    top->rst_n = 1;

    // Packet destined for (0,0) -> Local on a default (0,0) router.
    const uint32_t packet = (0u << 24) | (0u << 16) | 0xCAFE;
    top->s_axis_tdata[0]  = packet;
    top->s_axis_tvalid[0] = 1;

    // sink for Local (index 4) stays not-ready for 30 cycles. shouldn't
    // drop the packet during this window - tvalid[4] must never fire
    // while tready[4] is low
    bool saw_spurious_valid = false;
    for (int cyc = 0; cyc < 30; cyc++) {
        top->clk = 1; top->eval();
        if (top->m_axis_tvalid[4] && !top->m_axis_tready[4]) {
            saw_spurious_valid = true;
        }
        top->clk = 0; top->eval();
    }

    // stop offering it at the source - proves the router held it
    // internally instead of needing it kept presented
    top->s_axis_tvalid[0] = 0;

    // now let the sink go ready and see if it shows up intact on Local
    top->m_axis_tready[4] = 1;

    uint32_t observed = 0;
    bool arrived = false;
    for (int cyc = 0; cyc < 20 && !arrived; cyc++) {
        top->clk = 1; top->eval();
        if (top->m_axis_tvalid[4] && top->m_axis_tready[4]) {
            observed = top->m_axis_tdata[4];
            arrived = true;
        }
        top->clk = 0; top->eval();
    }

    std::cout << "Spurious valid-without-ready during backpressure window: "
              << (saw_spurious_valid ? "YES (BUG)" : "no") << "\n";
    std::cout << "Packet arrived after releasing backpressure: "
              << (arrived ? "yes" : "NO (packet lost - BUG)") << "\n";
    if (arrived) {
        std::cout << "Data match: " << ((observed == packet) ? "yes (0x" : "NO - CORRUPTED (0x")
                   << std::hex << observed << " vs expected 0x" << packet << std::dec << ")\n";
    }

    bool pass = arrived && (observed == packet) && !saw_spurious_valid;
    std::cout << (pass ? "PASS: packet survived backpressure intact\n"
                        : "FAIL: backpressure handling is broken\n");

    delete top;
    return pass ? 0 : 1;
}