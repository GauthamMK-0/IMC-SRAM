#include "Vimc_sram.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>

vluint64_t sim_time = 0;
const vluint64_t MAX_SIM_TIME = 500;

void tick(Vimc_sram* dut, VerilatedVcdC* tfp) {
    dut->clk = 0;
    dut->eval();
    tfp->dump(sim_time++);
    dut->clk = 1;
    dut->eval();
    tfp->dump(sim_time++);
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vimc_sram* dut = new Vimc_sram;
    VerilatedVcdC* tfp = new VerilatedVcdC;

    Verilated::traceEverOn(true);
    dut->trace(tfp, 99);
    tfp->open("imc_sram_wave.vcd");

    dut->clk = 0;
    dut->rst = 1;
    dut->start = 0;
    dut->row_addr = 0;
    dut->write_data = 0;
    dut->input_vector = 0;

    for (int i = 0; i < 5; i++) tick(dut, tfp);
    dut->rst = 0;

    dut->row_addr = 3;
    dut->write_data = 0b1010101010101010;
    dut->input_vector = 0b1111000011110000;

    dut->start = 1;
    tick(dut, tfp);
    dut->start = 0;

    // Simulate until DONE is asserted or timeout occurs
    while (!dut->done && sim_time < MAX_SIM_TIME) {
        tick(dut, tfp);
    }

    if (dut->done) {
        std::cout << "DONE asserted." << std::endl;
        std::cout << "Accumulated Output: " << dut->accum_out << std::endl;
    } else {
        std::cout << "Timeout. DONE not asserted." << std::endl;
    }

    tfp->close();
    delete dut;
    delete tfp;
    return 0;
}
