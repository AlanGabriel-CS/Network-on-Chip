#include "Varbiter.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

int main(int argc, char** argv) {
    Verilated::traceEverOn(true);
    Verilated::commandArgs(argc, argv);
    Varbiter* top = new Varbiter;

    // trace setup
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("arbiter.vcd");

    // initialize inputs
    top->clk = 0;
    top->rst_n = 0;
    top->request = 0;

    // reset sequence
    top->clk = 1; top->eval(); tfp->dump(1);
    top->rst_n = 1; top->clk = 0; top->eval(); tfp->dump(2);

    // test: request from ports 0 and 1
    top->request = 0b0011;
    top->clk = 1; top->eval(); tfp->dump(3);
    top->clk = 0; top->eval(); tfp->dump(4);

    // test: request from ports 2 and 3
    top->request = 0b1100;
    top->clk = 1; top->eval(); tfp->dump(5);
    top->clk = 0; top->eval(); tfp->dump(6);

    tfp->close();
    top->final();
    delete top;
    return 0;
}
