function CC.typeinf(interp::XInterpreter, frame::InferenceState)
    ret = @invoke typeinf(interp::AbstractInterpreter, frame::InferenceState)

    return ret
end

function CC.finish!(interp::XInterpreter, caller::InferenceResult)
    ret = @invoke finish!(interp::AbstractInterpreter, caller::InferenceResult)

    return ret
end

function CC._typeinf(interp::XInterpreter, frame::InferenceState)
    ret = @invoke _typeinf(interp::AbstractInterpreter, frame::InferenceState)

    return ret
end

function CC.maybe_compress_codeinfo(interp::XInterpreter, linfo::MethodInstance, ci::CodeInfo)
    ret = @invoke maybe_compress_codeinfo(interp::AbstractInterpreter, linfo::MethodInstance, ci::CodeInfo)

    return ret
end

function CC.transform_result_for_cache(interp::XInterpreter, linfo::MethodInstance,
                                    @nospecialize(inferred_result))
    ret = @invoke transform_result_for_cache(interp::AbstractInterpreter, linfo::MethodInstance,
                                             inferred_result)

    return ret
end

function CC.cache_result!(interp::XInterpreter, result::InferenceResult, valid_worlds::WorldRange)
    ret = @invoke cache_result!(interp::AbstractInterpreter, result::InferenceResult, valid_worlds::WorldRange)

    return ret
end

function CC.finish(me::InferenceState, interp::XInterpreter)
    ret = @invoke finish(me::InferenceState, interp::AbstractInterpreter)

    return ret
end

function CC.is_same_frame(interp::XInterpreter, linfo::MethodInstance, frame::InferenceState)
    ret = @invoke is_same_frame(interp::AbstractInterpreter, linfo::MethodInstance, frame::InferenceState)

    return ret
end

function CC.resolve_call_cycle!(interp::XInterpreter, linfo::MethodInstance, parent::InferenceState)
    ret = @invoke resolve_call_cycle!(interp::AbstractInterpreter, linfo::MethodInstance, parent::InferenceState)

    return ret
end

function CC.typeinf_edge(interp::XInterpreter, method::Method, @nospecialize(atypes), sparams::SimpleVector, caller::InferenceState)
    ret = @invoke typeinf_edge(interp::AbstractInterpreter, method::Method, atypes, sparams::SimpleVector, caller::InferenceState)

    return ret
end
