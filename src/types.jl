# define our `AbstractInterpreter` (not fancier one, which set ups another abstract layer and allows yet more composablility)
# and satisfy its interface requirements

"""
    XInterpreter <: AbstractInterpreter

Basically, this `AbstractInterpreter` just traces the original `NativeInterpreter`'s
abstract interpretation methods, but with additional tweaks to enable extensible inspections:
- `XInterpreter` setups its own code cache (both global and local), which can be referred later
- Entry points of the `XInterpreter`'s compilation pipeline can easily configure its parameters,
  and each different configuration will yield a different code cache.
"""
mutable struct XInterpreter <: AbstractInterpreter
    # NativeInterpreter
    native::NativeInterpreter
    optimize::Bool
    compress::Bool
    discard_trees::Bool
    verbose_stmt_info::Bool

    # customized cache
    cache_key::UInt

    # debug
    depth::Int

    function XInterpreter(world             = get_world_counter();
                          inf_params        = nothing,
                          opt_params        = nothing,
                          optimize          = true,
                          compress          = false,
                          discard_trees     = false,
                          verbose_stmt_info = false,
                          xconfigs...)
        isnothing(inf_params) && (inf_params = XInferenceParams(;    xconfigs...))
        isnothing(opt_params) && (opt_params = XOptimizationParams(; xconfigs...))

        # generate cache key, and initialize the cache partition
        h = @static UInt === UInt64 ? 0xacd4508fa540c2c9 : 0x43e699d6
        h = hash(inf_params, h)
        h = hash(opt_params, h)
        h = hash(optimize, h)
        h = hash(compress, h)
        cache_key = hash(discard_trees, h)
        __init_cache!(cache_key)

        native = NativeInterpreter(world; inf_params, opt_params)
        return new(native,
                   optimize,
                   compress,
                   discard_trees,
                   verbose_stmt_info,
                   cache_key,
                   0,
                   )
    end
end

# define these functions just to make them able to accept other JET configrations
XInferenceParams(; ipo_constant_propagation::Bool        = true,
                   aggressive_constant_propagation::Bool = false,
                   unoptimize_throw_blocks::Bool         = true,
                   max_methods::Int                      = 3,
                   union_splitting::Int                  = 4,
                   apply_union_enum::Int                 = 8,
                   tupletype_depth::Int                  = 3,
                   tuple_splat::Int                      = 32,
                   __xconfigs...) =
    return InferenceParams(; ipo_constant_propagation,
                             aggressive_constant_propagation,
                             unoptimize_throw_blocks,
                             max_methods,
                             union_splitting,
                             apply_union_enum,
                             tupletype_depth,
                             tuple_splat,
                             )
XOptimizationParams(; inlining::Bool                = inlining_enabled(),
                      inline_cost_threshold::Int    = 100,
                      inline_nonleaf_penalty::Int   = 1000,
                      inline_tupleret_bonus::Int    = 250,
                      inline_error_path_cost::Int   = 20,
                      max_methods::Int              = 3,
                      tuple_splat::Int              = 32,
                      union_splitting::Int          = 4,
                      unoptimize_throw_blocks::Bool = true,
                      __xconfigs...) =
    return OptimizationParams(; inlining,
                                inline_cost_threshold,
                                inline_nonleaf_penalty,
                                inline_tupleret_bonus,
                                inline_error_path_cost,
                                max_methods,
                                tuple_splat,
                                union_splitting,
                                unoptimize_throw_blocks,
                                )
# # assert here that they create same objects as the original constructors
@assert XInferenceParams()    == InferenceParams()
@assert XOptimizationParams() == OptimizationParams()

CC.InferenceParams(interp::XInterpreter)    = InferenceParams(interp.native)
CC.OptimizationParams(interp::XInterpreter) = OptimizationParams(interp.native)
CC.get_world_counter(interp::XInterpreter)  = get_world_counter(interp.native)

CC.lock_mi_inference(::XInterpreter,   ::MethodInstance) = nothing
CC.unlock_mi_inference(::XInterpreter, ::MethodInstance) = nothing

CC.add_remark!(interp::XInterpreter, sv, s) = add_remark!(interp.native, sv, s)

CC.may_optimize(interp::XInterpreter)      = interp.optimize
CC.may_compress(interp::XInterpreter)      = interp.compress
CC.may_discard_trees(interp::XInterpreter) = interp.discard_trees
CC.verbose_stmt_info(interp::XInterpreter) = interp.verbose_stmt_info
