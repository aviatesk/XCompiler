module XCompiler

# overloads
# ---------

import Core.Compiler:
    # interfaces.jl
    InferenceParams,
    OptimizationParams,
    get_world_counter,
    get_inference_cache,
    lock_mi_inference,
    unlock_mi_inference,
    add_remark!,
    may_optimize,
    may_compress,
    may_discard_trees,
    # cicache.jl
    code_cache,
    get_inference_cache,
    cache_lookup,
    # inferencestate.jl
    InferenceState,
    method_table,
    # tfuncs.jl
    builtin_tfunction,
    return_type_tfunc,
    # abstractinterpretation.jl
    abstract_call_gf_by_type,
    bail_out_toplevel_call,
    bail_out_call,
    bail_out_apply,
    add_call_backedges!,
    abstract_call_method_with_const_args,
    maybe_get_const_prop_profitable,
    const_prop_entry_heuristic,
    const_prop_argument_heuristic,
    const_prop_rettype_heuristic,
    force_const_prop,
    const_prop_function_heuristic,
    const_prop_methodinstance_heuristic,
    abstract_call_method,
    precise_container_type,
    abstract_iteration,
    abstract_apply,
    bail_out_apply,
    abstract_call_builtin,
    abstract_invoke,
    abstract_call_known,
    abstract_call,
    abstract_eval_cfunction,
    abstract_eval_value_expr,
    abstract_eval_special_value,
    abstract_eval_value,
    abstract_eval_statement,
    typeinf_local,
    typeinf_nocycle,
    # optimize.jl
    IRCode,
    OptimizationState,
    finish,
    optimize,
    # typeinfer.jl
    typeinf,
    _typeinf,
    finish!,
    maybe_compress_codeinfo,
    transform_result_for_cache,
    cache_result!,
    finish,
    is_same_frame,
    resolve_call_cycle!,
    typeinf_edge

# imports
# -------

import Core:
    CodeInfo,
    MethodInstance,
    CodeInstance,
    MethodMatch,
    LineInfoNode,
    SimpleVector,
    Builtin,
    Typeof,
    svec

import Core.Compiler:
    AbstractInterpreter,
    NativeInterpreter,
    InferenceResult,
    WorldRange,
    WorldView,
    MethodCallResult,
    VarTable,
    to_tuple_type,
    _methods_by_ftype,
    specialize_method,
    inlining_enabled

import Base:
    unwrap_unionall,
    rewrap_unionall,
    destructure_callex

import Base.Meta:
    isexpr,
    lower

using InteractiveUtils

const CC = Core.Compiler

function __init__()
    @eval begin
        using Revise

        files = normpath.(@__DIR__, (readdir(@__DIR__)))
        Revise.add_callback(files) do
            __clear_cache!()
        end
    end
end

# utilties
# --------

"""
    @invoke f(arg::T, ...; kwargs...)

Provides a convenient way to call [`invoke`](@ref);
`@invoke f(arg1::T1, arg2::T2; kwargs...)` will be expanded into `invoke(f, Tuple{T1,T2}, arg1, arg2; kwargs...)`.
When an argument's type annotation is omitted, it's specified as `Any` argument, e.g.
`@invoke f(arg1::T, arg2)` will be expanded into `invoke(f, Tuple{T,Any}, arg1, arg2)`.

This could be used to call down to `NativeInterpreter`'s abstract interpretation method
while passing `XInterpreter` so that subsequent calls of abstract interpretation methods
are dispatched to those overloaded against `XInterpreter`.

E.g. call down to `abstract_call_gf_by_type(::NativeInterpreter, ...)` within `abstract_call_gf_by_type(::XInterpreter, ...)`:
```julia
function Core.Compiler.abstract_call_gf_by_type(interp::XInterpreter, ...)
    ...
    @invoke Core.Compiler.abstract_call_gf_by_type(interp::AbstractInterpreter, ...) # within this call, methods overloaded on `XInterpreter` will still be dispatched.
    ...
end
```
"""
macro invoke(ex)
    f, args, kwargs = destructure_callex(ex)
    arg2typs = map(args) do x
        if isexpr(x, :macrocall) && first(x.args) === Symbol("@nospecialize")
            x = last(x.args)
        end
        isexpr(x, :(::)) ? (x.args...,) : (x, GlobalRef(Core, :Any))
    end
    args, argtypes = first.(arg2typs), last.(arg2typs)
    return esc(:($(GlobalRef(Core, :invoke))($(f), Tuple{$(argtypes...)}, $(args...); $(kwargs...))))
end

# for inspection
macro lwr(ex) QuoteNode(lower(__module__, ex)) end
macro src(ex) QuoteNode(first(lower(__module__, ex).args)) end

# includes
# --------

include("types.jl")
include("inferencestate.jl")
include("tfuncs.jl")
include("abstractinterpretation.jl")
include("optimize.jl")
include("typeinfer.jl")
include("xcache.jl")

# entry
# -----

struct XResult
    interp::XInterpreter
    frame::InferenceState
end
function Base.show(io::IO, res::XResult)
    (; interp, frame) = res
    print(io, "XResult(XInterpreter($(interp.cache_key)), InferenceFrame($(frame.result)))")
end

macro enter_call(ex0...)
    return InteractiveUtils.gen_call_with_extracted_types_and_kwargs(__module__, :enter_call, ex0)
end

function enter_call(@nospecialize(f), @nospecialize(types=Tuple{});
                    kwargs...)
    ft = Typeof(f)
    tt = if isa(types, Type)
        u = unwrap_unionall(types)
        rewrap_unionall(Tuple{ft, u.parameters...}, types)
    else
        Tuple{ft, types...}
    end
    interp = XInterpreter(; kwargs...)
    return enter_gf_by_type!(interp, tt)
end

# TODO `enter_call_builtin!` ?
function enter_gf_by_type!(interp::XInterpreter,
                           @nospecialize(tt::Type{<:Tuple}),
                           world::UInt = get_world_counter(interp),
                           )
    mms = _methods_by_ftype(tt, InferenceParams(interp).MAX_METHODS, world)
    @assert mms !== false "unable to find matching method for $(tt)"

    filter!(mm->mm.spec_types===tt, mms)
    @assert length(mms) == 1 "unable to find single target method for $(tt)"

    mm = first(mms)::MethodMatch

    return enter_method_signature!(interp, mm.method, mm.spec_types, mm.sparams)
end

function enter_method_signature!(interp::XInterpreter,
                                 m::Method,
                                 @nospecialize(atype),
                                 sparams::SimpleVector,
                                 world::UInt = get_world_counter(interp),
                                 )
    mi = specialize_method(m, atype, sparams)

    result = InferenceResult(mi)

    frame = InferenceState(result, #= cached =# true, interp)

    typeinf(interp, frame)

    return XResult(interp, frame)
end

function enter_method!(interp::XInterpreter,
                       m::Method,
                       world::UInt = get_world_counter(interp),
                       )
    return enter_method_signature!(interp, m, m.sig, sparams_from_method_signature(m), world)
end

function sparams_from_method_signature(m)
    s = TypeVar[]
    sig = m.sig
    while isa(sig, UnionAll)
        push!(s, sig.var)
        sig = sig.body
    end
    return svec(s...)
end

# exports

export
    @enter_call,
    enter_call

end # module XCompiler
