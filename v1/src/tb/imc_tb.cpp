// ============================================================================
// IMC-SRAM Testbench — Verilator C++ Driver
// ============================================================================
//
// Tests three operations:
//   1. WRITE  — Load an 8×8 weight matrix row by row
//   2. READ   — Read back and verify stored weights
//   3. COMPUTE — Perform MAC and compare with software golden model
//
// The testbench prints formatted tables for easy understanding.
// ============================================================================

#include "Vimc_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <cstdio>
#include <cstdint>
#include <cstdlib>

// ── Parameters (must match imc_pkg.vh) ──────────────────────────────────────
static const int ROWS       = 8;
static const int COLS       = 8;
static const int DAC_BITS   = 3;
static const int MAC_ACC_W  = 8;

// ── Simulation time tracking ────────────────────────────────────────────────
static vluint64_t sim_time = 0;

// ── Clock tick ──────────────────────────────────────────────────────────────
static void tick(Vimc_top* dut, VerilatedVcdC* tfp) {
    dut->clk = 0;
    dut->eval();
    if (tfp) tfp->dump(sim_time++);
    dut->clk = 1;
    dut->eval();
    if (tfp) tfp->dump(sim_time++);
}

// ── Wait N cycles ───────────────────────────────────────────────────────────
static void wait_cycles(Vimc_top* dut, VerilatedVcdC* tfp, int n) {
    for (int i = 0; i < n; i++) tick(dut, tfp);
}

// ── Wait for result_valid ───────────────────────────────────────────────────
static bool wait_valid(Vimc_top* dut, VerilatedVcdC* tfp, int timeout = 20) {
    for (int i = 0; i < timeout; i++) {
        tick(dut, tfp);
        if (dut->result_valid) return true;
    }
    return false;
}

// ── Write one row ───────────────────────────────────────────────────────────
static void write_row(Vimc_top* dut, VerilatedVcdC* tfp,
                       int row, uint8_t data) {
    dut->op_mode    = 1;  // OP_WRITE
    dut->row_addr   = row;
    dut->write_data = data;
    dut->start      = 1;
    tick(dut, tfp);
    dut->start      = 0;
    wait_valid(dut, tfp);
    wait_cycles(dut, tfp, 1);
}

// ── Read one row ────────────────────────────────────────────────────────────
static uint8_t read_row(Vimc_top* dut, VerilatedVcdC* tfp, int row) {
    dut->op_mode  = 3;  // OP_READ
    dut->row_addr = row;
    dut->start    = 1;
    tick(dut, tfp);
    dut->start    = 0;
    wait_valid(dut, tfp);
    uint8_t val = dut->read_data & 0xFF;
    wait_cycles(dut, tfp, 1);
    return val;
}

// ── Compute MAC ─────────────────────────────────────────────────────────────
static void compute_mac(Vimc_top* dut, VerilatedVcdC* tfp,
                         uint32_t input_vec, int8_t results[COLS]) {
    dut->op_mode      = 2;  // OP_COMPUTE
    dut->input_vector = input_vec;
    dut->start        = 1;
    tick(dut, tfp);
    dut->start        = 0;
    wait_valid(dut, tfp);

    // Extract signed 8-bit results per column from 64-bit packed bus
    uint64_t raw = dut->mac_result;
    for (int c = 0; c < COLS; c++) {
        results[c] = (int8_t)((raw >> (c * MAC_ACC_W)) & 0xFF);
    }
    wait_cycles(dut, tfp, 1);
}

// ── Software golden model ───────────────────────────────────────────────────
static void golden_mac(uint8_t weights[ROWS], uint8_t input_levels[ROWS],
                        int8_t expected[COLS]) {
    for (int c = 0; c < COLS; c++) {
        int sum = 0;
        for (int r = 0; r < ROWS; r++) {
            int w_bit = (weights[r] >> c) & 1;   // weight bit [r][c]
            int x     = input_levels[r];           // DAC level for row r
            int sign  = w_bit ? +1 : -1;          // {0,1} → {−1,+1}
            sum += sign * x;
        }
        expected[c] = (int8_t)sum;
    }
}

// ── Pack input levels into bus ──────────────────────────────────────────────
static uint32_t pack_inputs(uint8_t levels[ROWS]) {
    uint32_t bus = 0;
    for (int r = 0; r < ROWS; r++) {
        bus |= ((uint32_t)(levels[r] & 0x7)) << (r * DAC_BITS);
    }
    return bus;
}

// ── Print helpers ───────────────────────────────────────────────────────────
static void print_separator() {
    printf("────────────────────────────────────────────────────────\n");
}

static void print_weight_matrix(uint8_t weights[ROWS]) {
    printf("\n  Weight Matrix W[%d×%d] (binary):\n", ROWS, COLS);
    printf("         C7 C6 C5 C4 C3 C2 C1 C0\n");
    for (int r = 0; r < ROWS; r++) {
        printf("  R%d:  [", r);
        for (int c = COLS - 1; c >= 0; c--) {
            printf(" %d", (weights[r] >> c) & 1);
        }
        printf(" ]  (0x%02X)\n", weights[r]);
    }
}

static void print_input_vector(uint8_t levels[ROWS]) {
    printf("\n  Input Vector x[%d] (DAC levels 0–7):\n  [", ROWS);
    for (int r = 0; r < ROWS; r++) {
        printf(" %d", levels[r]);
    }
    printf(" ]\n");
}

static void print_mac_results(int8_t hw[COLS], int8_t sw[COLS]) {
    printf("\n  MAC Results (per column):\n");
    printf("  Col:      ");
    for (int c = 0; c < COLS; c++) printf("C%-3d ", c);
    printf("\n  Hardware:  ");
    for (int c = 0; c < COLS; c++) printf("%-4d ", hw[c]);
    printf("\n  Expected:  ");
    for (int c = 0; c < COLS; c++) printf("%-4d ", sw[c]);
    printf("\n");
}

// ════════════════════════════════════════════════════════════════════════════
//  MAIN
// ════════════════════════════════════════════════════════════════════════════
int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vimc_top* dut = new Vimc_top;
    VerilatedVcdC* tfp = new VerilatedVcdC;
    Verilated::traceEverOn(true);
    dut->trace(tfp, 99);
    tfp->open("imc_sram_wave.vcd");

    int total_tests = 0, pass_count = 0;

    // ── Reset ───────────────────────────────────────────────────────────
    dut->rst_n        = 0;
    dut->start        = 0;
    dut->op_mode      = 0;
    dut->row_addr     = 0;
    dut->write_data   = 0;
    dut->input_vector = 0;
    wait_cycles(dut, tfp, 5);
    dut->rst_n = 1;
    wait_cycles(dut, tfp, 2);

    printf("\n");
    print_separator();
    printf("  IMC-SRAM Research Simulation Testbench\n");
    printf("  Array: %d rows × %d cols | DAC: %d-bit | ACC: %d-bit\n",
           ROWS, COLS, DAC_BITS, MAC_ACC_W);
    print_separator();

    // ── Weight matrix (hand-chosen for clarity) ─────────────────────────
    uint8_t weights[ROWS] = {
        0xA5,  // 10100101
        0x3C,  // 00111100
        0xFF,  // 11111111
        0x00,  // 00000000
        0x55,  // 01010101
        0xAA,  // 10101010
        0xF0,  // 11110000
        0x0F   // 00001111
    };

    // ════════════════════════════════════════════════════════════════════
    //  TEST 1: Write Weight Matrix
    // ════════════════════════════════════════════════════════════════════
    printf("\n▶ TEST 1: Writing weight matrix into SRAM...\n");
    for (int r = 0; r < ROWS; r++) {
        write_row(dut, tfp, r, weights[r]);
    }
    printf("  ✓ All %d rows written.\n", ROWS);
    print_weight_matrix(weights);

    // ════════════════════════════════════════════════════════════════════
    //  TEST 2: Read Back and Verify
    // ════════════════════════════════════════════════════════════════════
    printf("\n▶ TEST 2: Reading back and verifying weights...\n");
    bool read_pass = true;
    for (int r = 0; r < ROWS; r++) {
        uint8_t rd = read_row(dut, tfp, r);
        if (rd != weights[r]) {
            printf("  ✗ Row %d MISMATCH: got 0x%02X, expected 0x%02X\n",
                   r, rd, weights[r]);
            read_pass = false;
        }
    }
    total_tests++;
    if (read_pass) {
        printf("  ✓ All rows verified correctly.\n");
        pass_count++;
    }

    // ════════════════════════════════════════════════════════════════════
    //  TEST 3: MAC with uniform input
    // ════════════════════════════════════════════════════════════════════
    printf("\n▶ TEST 3: MAC — uniform input (all rows = 4)...\n");
    {
        uint8_t inputs[ROWS] = {4, 4, 4, 4, 4, 4, 4, 4};
        int8_t hw_res[COLS], sw_res[COLS];
        golden_mac(weights, inputs, sw_res);
        compute_mac(dut, tfp, pack_inputs(inputs), hw_res);
        print_input_vector(inputs);
        print_mac_results(hw_res, sw_res);

        bool ok = true;
        for (int c = 0; c < COLS; c++)
            if (hw_res[c] != sw_res[c]) ok = false;
        total_tests++;
        if (ok) { printf("  ✓ PASS\n"); pass_count++; }
        else      printf("  ✗ FAIL\n");
    }

    // ════════════════════════════════════════════════════════════════════
    //  TEST 4: MAC with varied input
    // ════════════════════════════════════════════════════════════════════
    printf("\n▶ TEST 4: MAC — varied input [1,2,3,4,5,6,7,0]...\n");
    {
        uint8_t inputs[ROWS] = {1, 2, 3, 4, 5, 6, 7, 0};
        int8_t hw_res[COLS], sw_res[COLS];
        golden_mac(weights, inputs, sw_res);
        compute_mac(dut, tfp, pack_inputs(inputs), hw_res);
        print_input_vector(inputs);
        print_mac_results(hw_res, sw_res);

        bool ok = true;
        for (int c = 0; c < COLS; c++)
            if (hw_res[c] != sw_res[c]) ok = false;
        total_tests++;
        if (ok) { printf("  ✓ PASS\n"); pass_count++; }
        else      printf("  ✗ FAIL\n");
    }

    // ════════════════════════════════════════════════════════════════════
    //  TEST 5: MAC — max input (stress)
    // ════════════════════════════════════════════════════════════════════
    printf("\n▶ TEST 5: MAC — max input (all rows = 7)...\n");
    {
        uint8_t inputs[ROWS] = {7, 7, 7, 7, 7, 7, 7, 7};
        int8_t hw_res[COLS], sw_res[COLS];
        golden_mac(weights, inputs, sw_res);
        compute_mac(dut, tfp, pack_inputs(inputs), hw_res);
        print_input_vector(inputs);
        print_mac_results(hw_res, sw_res);

        bool ok = true;
        for (int c = 0; c < COLS; c++)
            if (hw_res[c] != sw_res[c]) ok = false;
        total_tests++;
        if (ok) { printf("  ✓ PASS\n"); pass_count++; }
        else      printf("  ✗ FAIL\n");
    }

    // ════════════════════════════════════════════════════════════════════
    //  TEST 6: MAC — zero input
    // ════════════════════════════════════════════════════════════════════
    printf("\n▶ TEST 6: MAC — zero input (all rows = 0)...\n");
    {
        uint8_t inputs[ROWS] = {0, 0, 0, 0, 0, 0, 0, 0};
        int8_t hw_res[COLS], sw_res[COLS];
        golden_mac(weights, inputs, sw_res);
        compute_mac(dut, tfp, pack_inputs(inputs), hw_res);
        print_input_vector(inputs);
        print_mac_results(hw_res, sw_res);

        bool ok = true;
        for (int c = 0; c < COLS; c++)
            if (hw_res[c] != sw_res[c]) ok = false;
        total_tests++;
        if (ok) { printf("  ✓ PASS\n"); pass_count++; }
        else      printf("  ✗ FAIL\n");
    }

    // ── Summary ─────────────────────────────────────────────────────────
    printf("\n");
    print_separator();
    printf("  Results: %d / %d tests PASSED\n", pass_count, total_tests);
    print_separator();
    printf("\n  VCD waveform saved to: imc_sram_wave.vcd\n\n");

    tfp->close();
    delete dut;
    delete tfp;

    return (pass_count == total_tests) ? 0 : 1;
}
