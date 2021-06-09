function CC.abstract_call_gf_by_type(interp::XInterpreter, @nospecialize(f),
                                     fargs::Union{Nothing,Vector{Any}}, argtypes::Vector{Any}, @nospecialize(atype),
                                     sv::InferenceState, max_methods::Int = InferenceParams(interp).MAX_METHODS)
    ret = @invoke abstract_call_gf_by_type(interp::AbstractInterpreter, @nospecialize(f),
                                           fargs::Union{Nothing,Vector{Any}}, argtypes::Vector{Any}, @nospecialize(atype),
                                           sv::InferenceState, max_methods::Int)

    return ret
end

function CC.bail_out_toplevel_call(interp::XInterpreter, @nospecialize(sig), sv)
    ret = @invoke bail_out_toplevel_call(interp::AbstractInterpreter, @nospecialize(sig), sv)

    return ret
end

function CC.bail_out_call(interp::XInterpreter, @nospecialize(t), sv)
    ret = @invoke bail_out_call(interp::AbstractInterpreter, @nospecialize(t), sv)

    return ret
end

function CC.add_call_backedges!(interp::XInterpreter,
                                @nospecialize(rettype),
                                edges::Vector{MethodInstance},
                                fullmatch::Vector{Bool}, mts::Vector{Core.MethodTable}, @nospecialize(atype),
                                sv::InferenceState)
    ret = @invoke add_call_backedges!(interp::AbstractInterpreter,
                                      @nospecialize(rettype),
                                      edges::Vector{MethodInstance},
                                      fullmatch::Vector{Bool}, mts::Vector{Core.MethodTable}, @nospecialize(atype),
                                      sv::InferenceState)

    return ret
end

function CC.abstract_call_method_with_const_args(interp::XInterpreter, result::MethodCallResult,
                                                 @nospecialize(f), argtypes::Vector{Any}, match::MethodMatch,
                                                 sv::InferenceState, va_override::Bool)
    ret = @invoke abstract_call_method_with_const_args(interp::AbstractInterpreter, result::MethodCallResult,
                                                       @nospecialize(f), argtypes::Vector{Any}, match::MethodMatch,
                                                       sv::InferenceState, va_override::Bool)

    return ret
end

function CC.maybe_get_const_prop_profitable(interp::XInterpreter, result::MethodCallResult,
                                         @nospecialize(f), argtypes::Vector{Any}, match::MethodMatch,
                                         sv::InferenceState)
    ret = @invoke maybe_get_const_prop_profitable(interp::AbstractInterpreter, result::MethodCallResult,
                                                  @nospecialize(f), argtypes::Vector{Any}, match::MethodMatch,
                                                  sv::InferenceState)

    return ret
end

function CC.const_prop_entry_heuristic(interp::XInterpreter, result::MethodCallResult, sv::InferenceState)
    ret = @invoke const_prop_entry_heuristic(interp::AbstractInterpreter, result::MethodCallResult, sv::InferenceState)

    return ret
end

function CC.const_prop_argument_heuristic(interp::XInterpreter, argtypes::Vector{Any})
    ret = @invoke const_prop_argument_heuristic(interp::AbstractInterpreter, argtypes::Vector{Any})

    return ret
end

function CC.const_prop_rettype_heuristic(interp::XInterpreter, @nospecialize(rettype))
    ret = @invoke const_prop_rettype_heuristic(interp::AbstractInterpreter, @nospecialize(rettype))

    return ret
end

function CC.force_const_prop(interp::XInterpreter, @nospecialize(f), method::Method)
    ret = @invoke force_const_prop(interp::AbstractInterpreter, @nospecialize(f), method::Method)

    return ret
end

function CC.const_prop_function_heuristic(interp::XInterpreter, @nospecialize(f), argtypes::Vector{Any}, nargs::Int, allconst::Bool)
    ret = @invoke const_prop_function_heuristic(interp::AbstractInterpreter, @nospecialize(f), argtypes::Vector{Any}, nargs::Int, allconst::Bool)

    return ret
end

function CC.const_prop_methodinstance_heuristic(interp::XInterpreter, method::Method, mi::MethodInstance)
    ret = @invoke const_prop_methodinstance_heuristic(interp::AbstractInterpreter, method::Method, mi::MethodInstance)

    return ret
end

function CC.abstract_call_method(interp::XInterpreter, method::Method, @nospecialize(sig), sparams::SimpleVector, hardlimit::Bool, sv::InferenceState)
    ret = @invoke abstract_call_method(interp::AbstractInterpreter, method::Method, sig, sparams::SimpleVector, hardlimit::Bool, sv::InferenceState)

    return ret
end

function CC.precise_container_type(interp::XInterpreter, @nospecialize(itft), @nospecialize(typ), sv::InferenceState)
    ret = @invoke precise_container_type(interp::AbstractInterpreter, itft, typ, sv::InferenceState)

    return ret
end

function CC.abstract_iteration(interp::XInterpreter, @nospecialize(itft), @nospecialize(itertype), sv::InferenceState)
    ret = @invoke abstract_iteration(interp::AbstractInterpreter, itft, itertype, sv::InferenceState)

    return ret
end

function CC.abstract_apply(interp::XInterpreter, @nospecialize(itft), @nospecialize(aft),    aargtypes::Vector{Any}, sv::InferenceState,
                        max_methods::Int = InferenceParams(interp).MAX_METHODS)
    ret = @invoke abstract_apply(interp::AbstractInterpreter, itft, aft, aargtypes::Vector{Any}, sv::InferenceState,
                                 max_methods::Int)

    return ret
end

function CC.bail_out_apply(interp::XInterpreter, @nospecialize(t), sv)
    ret = @invoke bail_out_apply(interp::AbstractInterpreter, @nospecialize(t), sv)

    return ret
end

function CC.abstract_call_builtin(interp::XInterpreter, f::Builtin, fargs::Union{Nothing,Vector{Any}},
                               argtypes::Vector{Any}, sv::InferenceState, max_methods::Int)
    ret = @invoke abstract_call_builtin(interp::AbstractInterpreter, f::Builtin, fargs::Union{Nothing,Vector{Any}},
                                        argtypes::Vector{Any}, sv::InferenceState, max_methods::Int)

    return ret
end

function CC.abstract_invoke(interp::XInterpreter, argtypes::Vector{Any}, sv::InferenceState)
    ret = @invoke abstract_invoke(interp::AbstractInterpreter, argtypes::Vector{Any}, sv::InferenceState)

    return ret
end

function CC.abstract_call_known(interp::XInterpreter, @nospecialize(f),
                                fargs::Union{Nothing,Vector{Any}}, argtypes::Vector{Any},
                                sv::InferenceState,
                                max_methods::Int = InferenceParams(interp).MAX_METHODS)
    ret = @invoke abstract_call_known(interp::AbstractInterpreter, f,
                                      fargs::Union{Nothing,Vector{Any}}, argtypes::Vector{Any},
                                      sv::InferenceState,
                                      max_methods::Int)
end

function CC.abstract_call(interp::XInterpreter, fargs::Union{Nothing,Vector{Any}}, argtypes::Vector{Any},
                       sv::InferenceState, max_methods::Int = InferenceParams(interp).MAX_METHODS)
    ret = @invoke abstract_call(interp::AbstractInterpreter, fargs::Union{Nothing,Vector{Any}}, argtypes::Vector{Any},
                                sv::InferenceState, max_methods::Int)

    return ret
end

function CC.abstract_eval_cfunction(interp::XInterpreter, e::Expr, vtypes::VarTable, sv::InferenceState)
    ret = @invoke abstract_eval_cfunction(interp::AbstractInterpreter, e::Expr, vtypes::VarTable, sv::InferenceState)

    return ret
end

function CC.abstract_eval_value_expr(interp::XInterpreter, e::Expr, vtypes::VarTable, sv::InferenceState)
    ret = @invoke abstract_eval_value_expr(interp::AbstractInterpreter, e::Expr, vtypes::VarTable, sv::InferenceState)

    return ret
end

function CC.abstract_eval_special_value(interp::XInterpreter, @nospecialize(e), vtypes::VarTable, sv::InferenceState)
    ret = @invoke abstract_eval_special_value(interp::AbstractInterpreter, e, vtypes::VarTable, sv::InferenceState)

    return ret
end

function CC.abstract_eval_value(interp::XInterpreter, @nospecialize(e), vtypes::VarTable, sv::InferenceState)
    ret = @invoke abstract_eval_value(interp::AbstractInterpreter, e, vtypes::VarTable, sv::InferenceState)

    return ret
end

function CC.abstract_eval_statement(interp::XInterpreter, @nospecialize(e), vtypes::VarTable, sv::InferenceState)
    ret = @invoke abstract_eval_statement(interp::AbstractInterpreter, e, vtypes::VarTable, sv::InferenceState)

    return ret
end

function CC.typeinf_local(interp::XInterpreter, frame::InferenceState)
    ret = @invoke typeinf_local(interp::AbstractInterpreter, frame::InferenceState)

    return ret
end

function CC.typeinf_nocycle(interp::XInterpreter, frame::InferenceState)
    ret = @invoke typeinf_nocycle(interp::AbstractInterpreter, frame::InferenceState)

    return ret
end
