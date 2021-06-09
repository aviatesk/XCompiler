function CC.OptimizationState(frame::InferenceState, params::OptimizationParams, interp::XInterpreter)
    ret = @invoke OptimizationState(frame::InferenceState, params::OptimizationParams, interp::AbstractInterpreter)

    return ret
end

# NOTE this one won't be called in the `XInterpreter` pipeline
function CC.OptimizationState(linfo::MethodInstance, src::CodeInfo, params::OptimizationParams, interp::XInterpreter)
    ret = @invoke OptimizationState(linfo::MethodInstance, src::CodeInfo, params::OptimizationParams, interp::AbstractInterpreter)

    return ret
end

# NOTE this one won't be called in the `XInterpreter` pipeline
function CC.OptimizationState(linfo::MethodInstance, params::OptimizationParams, interp::XInterpreter)
    ret = @invoke OptimizationState(linfo::MethodInstance, params::OptimizationParams, interp::AbstractInterpreter)

    return ret
end

function CC.finish(interp::XInterpreter, opt::OptimizationState, params::OptimizationParams, ir::IRCode, @nospecialize(result))
    ret = @invoke finish(interp::AbstractInterpreter, opt::OptimizationState, params::OptimizationParams, ir::IRCode, @nospecialize(result))

    return ret
end

function CC.optimize(interp::XInterpreter, opt::OptimizationState, params::OptimizationParams, @nospecialize(result))
    ret = @invoke optimize(interp::AbstractInterpreter, opt::OptimizationState, params::OptimizationParams, @nospecialize(result))

    return ret
end
