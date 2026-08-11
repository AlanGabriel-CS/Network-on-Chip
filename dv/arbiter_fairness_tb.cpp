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

    // reset
    for (int i = 0; i < 4; i++) {
        top->clk = !top->clk;
        top->eval();
    }
    top->rst_n = 1;

    std::array<int, 5> win_count = {0, 0, 0, 0, 0};
    const int NUM_CYCLES = 500;

    // hold all 5 requests continuously - worst case contention. a fair
    // round robin should grant each port ~NUM_CYCLES/5 times. the old
    // fixed-priority fallback would just give port 0 most of the grants
    top->request = 0b11111;

    for (int cyc = 0; cyc < NUM_CYCLES; cyc++) {
        top->clk = 1; top->eval();
        top->clk = 0; top->eval();

        for (int p = 0; p < 5; p++) {
            if (top->grant & (1 << p)) win_count[p]++;
        }
    }

    std::cout << "Grant distribution over " << NUM_CYCLES << " cycles (all ports always requesting):\n";
    int total = 0;
    for (int p = 0; p < 5; p++) {
        std::cout << "  Port " << p << ": " << win_count[p] << " grants\n";
        total += win_count[p];
    }
    std::cout << "  Total grants issued: " << total << "\n";

    // nobody should get less than half the ideal share or more than 2x it
    double ideal = static_cast<double>(total) / 5.0;
    bool fair = true;
    for (int p = 0; p < 5; p++) {
        if (win_count[p] < ideal * 0.5 || win_count[p] > ideal * 2.0) {
            fair = false;
        }
    }

    std::cout << (fair ? "PASS: grants are roughly balanced across all 5 ports\n"
                        : "FAIL: grant distribution is skewed - not round robin\n");

    delete top;
    return fair ? 0 : 1;
}