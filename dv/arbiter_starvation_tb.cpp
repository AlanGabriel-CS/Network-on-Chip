#include "Varbiter.h"
#include "verilated.h"
#include <iostream>
#include <array>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Varbiter* top = new Varbiter;

    top->clk = 0;
    top->rst_n = 0;
    top->request = 0;

    for (int i = 0; i < 4; i++) {
        top->clk = !top->clk;
        top->eval();
    }
    top->rst_n = 1;

    std::array<int, 5> win_count = {0, 0, 0, 0, 0};
    const int NUM_CYCLES = 500;

    // only ports 0 and 4 request, ports 1-3 never do. ptr lands on an
    // idle slot a lot this way, which is exactly when a buggy arbiter
    // falls back to favoring port 0 and starves port 4
    top->request = 0b10001;

    for (int cyc = 0; cyc < NUM_CYCLES; cyc++) {
        top->clk = 1; top->eval();
        top->clk = 0; top->eval();

        for (int p = 0; p < 5; p++) {
            if (top->grant & (1 << p)) win_count[p]++;
        }
    }

    std::cout << "Grant distribution over " << NUM_CYCLES << " cycles (only ports 0 & 4 requesting):\n";
    for (int p = 0; p < 5; p++) {
        std::cout << "  Port " << p << ": " << win_count[p] << " grants\n";
    }

    int total = win_count[0] + win_count[4];
    double share0 = 100.0 * win_count[0] / total;
    double share4 = 100.0 * win_count[4] / total;
    std::cout << "  Port 0 share: " << share0 << "%\n";
    std::cout << "  Port 4 share: " << share4 << "%\n";

    bool fair = (share0 > 40.0 && share0 < 60.0);
    std::cout << (fair ? "PASS: roughly 50/50 between the two active requesters\n"
                        : "FAIL: one port is starving the other\n");

    delete top;
    return fair ? 0 : 1;
}