function CC.builtin_tfunction(interp::XInterpreter, @nospecialize(f), argtypes::Array{Any,1},
                           sv::Union{InferenceState,Nothing})
    ret = @invoke builtin_tfunction(interp::AbstractInterpreter, f, argtypes::Array{Any,1},
                                    sv::Union{InferenceState,Nothing})

    return ret
end

function CC.return_type_tfunc(interp::XInterpreter, argtypes::Vector{Any}, sv::InferenceState)
    ret = @invoke return_type_tfunc(interp::AbstractInterpreter, argtypes::Vector{Any}, sv::InferenceState)

    return ret
end
