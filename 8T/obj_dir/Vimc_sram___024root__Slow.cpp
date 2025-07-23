// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vimc_sram.h for the primary calling header

#include "Vimc_sram__pch.h"
#include "Vimc_sram__Syms.h"
#include "Vimc_sram___024root.h"

void Vimc_sram___024root___ctor_var_reset(Vimc_sram___024root* vlSelf);

Vimc_sram___024root::Vimc_sram___024root(Vimc_sram__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Vimc_sram___024root___ctor_var_reset(this);
}

void Vimc_sram___024root::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

Vimc_sram___024root::~Vimc_sram___024root() {
}
