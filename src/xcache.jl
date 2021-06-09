# global
# ======

"""
    X_CODE_CACHE::$(typeof(X_CODE_CACHE))

Keeps `CodeInstance` cache associated with `mi::MethodInstace` that represent the result of
an inference on `mi` performed by `XInterpreter`.
The cache is partitioned by identities of each `XInterpreter`, and thus running a pipeline
with different configurations will yeild a different cache and never influenced by the
previous inference.
This cache is completely separated from the `NativeInterpreter`'s global cache, so that
XCompiler.jl's analysis never interacts with actual code execution (like, execution of `XCompiler` itself).
"""
const X_CODE_CACHE = IdDict{UInt, IdDict{MethodInstance,CodeInstance}}()

__init_cache!(h::UInt) = X_CODE_CACHE[h] = IdDict{MethodInstance,CodeInstance}()
__clear_cache!()       = empty!(X_CODE_CACHE)

function CC.code_cache(interp::XInterpreter)
    cache = XGlobalCache(interp)
    worlds = WorldRange(get_world_counter(interp))
    return WorldView(cache, worlds)
end

struct XGlobalCache
    interp::XInterpreter
end

# cache existence for this `analyzer` is ensured on its construction
x_code_cache(interp::XInterpreter)           = X_CODE_CACHE[interp.cache_key]
x_code_cache(wvc::WorldView{XGlobalCache}) = x_code_cache(wvc.cache.interp)

CC.haskey(wvc::WorldView{XGlobalCache}, mi::MethodInstance) = haskey(x_code_cache(wvc), mi)

function CC.get(wvc::WorldView{XGlobalCache}, mi::MethodInstance, default)
    ret = get(x_code_cache(wvc), mi, default)

    return ret
end

function CC.getindex(wvc::WorldView{XGlobalCache}, mi::MethodInstance)
    r = CC.get(wvc, mi, nothing)
    r === nothing && throw(KeyError(mi))
    return r::CodeInstance
end

function CC.setindex!(wvc::WorldView{XGlobalCache}, ci::CodeInstance, mi::MethodInstance)
    setindex!(x_code_cache(wvc), ci, mi)
    add_x_callback!(mi) # register the callback on invalidation
    return nothing
end

function add_x_callback!(linfo)
    if !isdefined(linfo, :callbacks)
        linfo.callbacks = Any[invalidate_x_cache!]
    else
        if !any(@nospecialize(cb)->cb===invalidate_x_cache!, linfo.callbacks)
            push!(linfo.callbacks, invalidate_x_cache!)
        end
    end
    return nothing
end

function invalidate_x_cache!(replaced, max_world, depth = 0)
    for cache in values(X_CODE_CACHE); delete!(cache, replaced); end

    if isdefined(replaced, :backedges)
        for mi in replaced.backedges
            mi = mi::MethodInstance
            if !any(cache->haskey(cache, mi), values(X_CODE_CACHE))
                continue # otherwise fall into infinite loop
            end
            invalidate_x_cache!(mi, max_world, depth+1)
        end
    end
    return nothing
end

# local
# =====

# to inspect local cache, we will just look for `get_inference_cache(interp.native)`
# and thus we won't create a global store to hold these caches

CC.get_inference_cache(interp::XInterpreter) = XLocalCache(interp)

struct XLocalCache
    interp::XInterpreter
end

# just bypass to the native one
function CC.cache_lookup(linfo::MethodInstance, given_argtypes::Vector{Any}, inf_cache::XLocalCache)
    ret = cache_lookup(linfo, given_argtypes, get_inference_cache(inf_cache.interp.native))

    return ret
end

# just bypass to the native one
function CC.push!(inf_cache::XLocalCache, inf_result::InferenceResult)
    ret = CC.push!(get_inference_cache(inf_cache.interp.native), inf_result)

    return ret
end
