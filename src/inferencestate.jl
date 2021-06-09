function CC.InferenceState(result::InferenceResult, src::CodeInfo,
                           cached::Bool, interp::XInterpreter)
    ret = @invoke InferenceState(result::InferenceResult, src::CodeInfo,
                                 cached::Bool, interp::AbstractInterpreter)

    return ret
end

function InferenceState(result::InferenceResult, cached::Bool, interp::XInterpreter)
    ret = @invoke InferenceState(result::InferenceResult, cached::Bool, interp::AbstractInterpreter)

    return ret
end

CC.method_table(interp::XInterpreter, sv::InferenceState) = sv.method_table
