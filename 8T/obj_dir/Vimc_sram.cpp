// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vimc_sram__pch.h"
#include "verilated_vcd_c.h"

//============================================================
// Constructors

Vimc_sram::Vimc_sram(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vimc_sram__Syms(contextp(), _vcname__, this)}
    , clk{vlSymsp->TOP.clk}
    , rst{vlSymsp->TOP.rst}
    , start{vlSymsp->TOP.start}
    , row_addr{vlSymsp->TOP.row_addr}
    , done{vlSymsp->TOP.done}
    , write_data{vlSymsp->TOP.write_data}
    , input_vector{vlSymsp->TOP.input_vector}
    , accum_out{vlSymsp->TOP.accum_out}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
    contextp()->traceBaseModelCbAdd(
        [this](VerilatedTraceBaseC* tfp, int levels, int options) { traceBaseModel(tfp, levels, options); });
}

Vimc_sram::Vimc_sram(const char* _vcname__)
    : Vimc_sram(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vimc_sram::~Vimc_sram() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vimc_sram___024root___eval_debug_assertions(Vimc_sram___024root* vlSelf);
#endif  // VL_DEBUG
void Vimc_sram___024root___eval_static(Vimc_sram___024root* vlSelf);
void Vimc_sram___024root___eval_initial(Vimc_sram___024root* vlSelf);
void Vimc_sram___024root___eval_settle(Vimc_sram___024root* vlSelf);
void Vimc_sram___024root___eval(Vimc_sram___024root* vlSelf);

void Vimc_sram::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vimc_sram::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vimc_sram___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_activity = true;
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vimc_sram___024root___eval_static(&(vlSymsp->TOP));
        Vimc_sram___024root___eval_initial(&(vlSymsp->TOP));
        Vimc_sram___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vimc_sram___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vimc_sram::eventsPending() { return false; }

uint64_t Vimc_sram::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* Vimc_sram::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vimc_sram___024root___eval_final(Vimc_sram___024root* vlSelf);

VL_ATTR_COLD void Vimc_sram::final() {
    Vimc_sram___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vimc_sram::hierName() const { return vlSymsp->name(); }
const char* Vimc_sram::modelName() const { return "Vimc_sram"; }
unsigned Vimc_sram::threads() const { return 1; }
void Vimc_sram::prepareClone() const { contextp()->prepareClone(); }
void Vimc_sram::atClone() const {
    contextp()->threadPoolpOnClone();
}
std::unique_ptr<VerilatedTraceConfig> Vimc_sram::traceConfig() const {
    return std::unique_ptr<VerilatedTraceConfig>{new VerilatedTraceConfig{false, false, false}};
};

//============================================================
// Trace configuration

void Vimc_sram___024root__trace_decl_types(VerilatedVcd* tracep);

void Vimc_sram___024root__trace_init_top(Vimc_sram___024root* vlSelf, VerilatedVcd* tracep);

VL_ATTR_COLD static void trace_init(void* voidSelf, VerilatedVcd* tracep, uint32_t code) {
    // Callback from tracep->open()
    Vimc_sram___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vimc_sram___024root*>(voidSelf);
    Vimc_sram__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (!vlSymsp->_vm_contextp__->calcUnusedSigs()) {
        VL_FATAL_MT(__FILE__, __LINE__, __FILE__,
            "Turning on wave traces requires Verilated::traceEverOn(true) call before time 0.");
    }
    vlSymsp->__Vm_baseCode = code;
    tracep->pushPrefix(std::string{vlSymsp->name()}, VerilatedTracePrefixType::SCOPE_MODULE);
    Vimc_sram___024root__trace_decl_types(tracep);
    Vimc_sram___024root__trace_init_top(vlSelf, tracep);
    tracep->popPrefix();
}

VL_ATTR_COLD void Vimc_sram___024root__trace_register(Vimc_sram___024root* vlSelf, VerilatedVcd* tracep);

VL_ATTR_COLD void Vimc_sram::traceBaseModel(VerilatedTraceBaseC* tfp, int levels, int options) {
    (void)levels; (void)options;
    VerilatedVcdC* const stfp = dynamic_cast<VerilatedVcdC*>(tfp);
    if (VL_UNLIKELY(!stfp)) {
        vl_fatal(__FILE__, __LINE__, __FILE__,"'Vimc_sram::trace()' called on non-VerilatedVcdC object;"
            " use --trace-fst with VerilatedFst object, and --trace-vcd with VerilatedVcd object");
    }
    stfp->spTrace()->addModel(this);
    stfp->spTrace()->addInitCb(&trace_init, &(vlSymsp->TOP));
    Vimc_sram___024root__trace_register(&(vlSymsp->TOP), stfp->spTrace());
}
