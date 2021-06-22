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
    nargs = Int(opt.nargs) - 1
    ir = x_run_passes(opt.src, nargs, opt)
    return finish(interp, opt, params, ir, result)
end

include("escape_analysis.jl")

# HACK enable copy and paste from Core.Compiler
function x_run_passes end
let f() = @eval CC function $(XCompiler).x_run_passes(ci::CodeInfo, nargs::Int, sv::OptimizationState)
               preserve_coverage = coverage_enabled(sv.mod)
               ir = convert_to_ircode(ci, copy_exprargs(ci.code), preserve_coverage, nargs, sv)
               ir = slot2reg(ir, ci, nargs, sv)
               #@Base.show ("after_construct", ir)
               ir = $(escape_analysis)(ir, ci)
               # TODO: Domsorting can produce an updated domtree - no need to recompute here
               @timeit "compact 1" ir = compact!(ir)
               @timeit "Inlining" ir = ssa_inlining_pass!(ir, ir.linetable, sv.inlining, ci.propagate_inbounds)
               #@timeit "verify 2" verify_ir(ir)
               ir = compact!(ir)
               #@Base.show ("before_sroa", ir)
               @timeit "SROA" ir = getfield_elim_pass!(ir)
               #@Base.show ir.new_nodes
               #@Base.show ("after_sroa", ir)
               ir = adce_pass!(ir)
               #@Base.show ("after_adce", ir)
               @timeit "type lift" ir = type_lift_pass!(ir)
               @timeit "compact 3" ir = compact!(ir)
               #@Base.show ir
               if JLOptions().debug_level == 2
                   @timeit "verify 3" (verify_ir(ir); verify_linetable(ir.linetable))
               end
               return ir
        end

    push!(__init_hooks__, f)
end
