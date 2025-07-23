// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vimc_sram.h for the primary calling header

#include "Vimc_sram__pch.h"
#include "Vimc_sram___024root.h"

void Vimc_sram___024root___eval_triggers__act(Vimc_sram___024root* vlSelf);
void Vimc_sram___024root___eval_act(Vimc_sram___024root* vlSelf);

bool Vimc_sram___024root___eval_phase__act(Vimc_sram___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vimc_sram___024root___eval_phase__act\n"); );
    Vimc_sram__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    VlTriggerVec<2> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vimc_sram___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelfRef.__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelfRef.__VactTriggered, vlSelfRef.__VnbaTriggered);
        vlSelfRef.__VnbaTriggered.thisOr(vlSelfRef.__VactTriggered);
        Vimc_sram___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

void Vimc_sram___024root___eval_nba(Vimc_sram___024root* vlSelf);

bool Vimc_sram___024root___eval_phase__nba(Vimc_sram___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vimc_sram___024root___eval_phase__nba\n"); );
    Vimc_sram__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelfRef.__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vimc_sram___024root___eval_nba(vlSelf);
        vlSelfRef.__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vimc_sram___024root___dump_triggers__ico(Vimc_sram___024root* vlSelf);
#endif  // VL_DEBUG
bool Vimc_sram___024root___eval_phase__ico(Vimc_sram___024root* vlSelf);
#ifdef VL_DEBUG
VL_ATTR_COLD void Vimc_sram___024root___dump_triggers__nba(Vimc_sram___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vimc_sram___024root___dump_triggers__act(Vimc_sram___024root* vlSelf);
#endif  // VL_DEBUG

void Vimc_sram___024root___eval(Vimc_sram___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vimc_sram___024root___eval\n"); );
    Vimc_sram__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*31:0*/ __VicoIterCount;
    CData/*0:0*/ __VicoContinue;
    IData/*31:0*/ __VnbaIterCount;
    CData/*0:0*/ __VnbaContinue;
    // Body
    __VicoIterCount = 0U;
    vlSelfRef.__VicoFirstIteration = 1U;
    __VicoContinue = 1U;
    while (__VicoContinue) {
        if (VL_UNLIKELY(((0x64U < __VicoIterCount)))) {
#ifdef VL_DEBUG
            Vimc_sram___024root___dump_triggers__ico(vlSelf);
#endif
            VL_FATAL_MT("rtl/imc_sram.v", 3, "", "Input combinational region did not converge.");
        }
        __VicoIterCount = ((IData)(1U) + __VicoIterCount);
        __VicoContinue = 0U;
        if (Vimc_sram___024root___eval_phase__ico(vlSelf)) {
            __VicoContinue = 1U;
        }
        vlSelfRef.__VicoFirstIteration = 0U;
    }
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY(((0x64U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vimc_sram___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("rtl/imc_sram.v", 3, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelfRef.__VactIterCount = 0U;
        vlSelfRef.__VactContinue = 1U;
        while (vlSelfRef.__VactContinue) {
            if (VL_UNLIKELY(((0x64U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                Vimc_sram___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("rtl/imc_sram.v", 3, "", "Active region did not converge.");
            }
            vlSelfRef.__VactIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VactIterCount);
            vlSelfRef.__VactContinue = 0U;
            if (Vimc_sram___024root___eval_phase__act(vlSelf)) {
                vlSelfRef.__VactContinue = 1U;
            }
        }
        if (Vimc_sram___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vimc_sram___024root___eval_debug_assertions(Vimc_sram___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vimc_sram___024root___eval_debug_assertions\n"); );
    Vimc_sram__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (VL_UNLIKELY(((vlSelfRef.clk & 0xfeU)))) {
        Verilated::overWidthError("clk");}
    if (VL_UNLIKELY(((vlSelfRef.rst & 0xfeU)))) {
        Verilated::overWidthError("rst");}
    if (VL_UNLIKELY(((vlSelfRef.start & 0xfeU)))) {
        Verilated::overWidthError("start");}
    if (VL_UNLIKELY(((vlSelfRef.row_addr & 0xf0U)))) {
        Verilated::overWidthError("row_addr");}
}
#endif  // VL_DEBUG
