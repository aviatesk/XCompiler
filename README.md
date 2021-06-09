### `Core.Compiler` playground

## Usage

This small toy module exports `@enter_call` and `enter_call`, which allows us to easily hook into any of `Core.Compiler`'s abstract interpretation / optimization routines.

`XCompiler` _just_ overloads everything of `Core.Compiler` defined on `AbstractInterpreter`.
So without any manual modification, `@enter_call f(args)` won't do nothing interesting other than what `@code_typed f(args)` can do for us:
```julia
julia> @enter_call sin(10)
XResult(XInterpreter(3763879814251570543), InferenceFrame(sin(::Int64) => Float64))
```

We're supposed to manually modify the code for each specific inspection/debug/development purpose.

Say we want to track the inference call graph with calculating some timing, we can just add the following diff and re-run `@enter_call sin(10)`:
```diff
diff --git a/src/typeinfer.jl b/src/typeinfer.jl
index ed731e4..3cd9d6d 100644
--- a/src/typeinfer.jl
+++ b/src/typeinfer.jl
@@ -1,9 +1,62 @@
 function CC.typeinf(interp::XInterpreter, frame::InferenceState)
+    io = stdout::IO
+    sec = time()
+    linfo = frame.linfo
+    depth = interp.depth
+
+    print_rails(io, depth)
+    printstyled(io, "┌ @ "; color = RAIL_COLORS[(depth+1)%N_RAILS+1])
+    print(io, linfo)
+    file, line = get_file_line(linfo)
+    print(io, ' ', file, ':', line)
+    is_constant_propagated(frame) && print(io, " (constant prop': ", frame.result.argtypes, ')')
+    println(io)
+    interp.depth += 1
+
     ret = @invoke typeinf(interp::AbstractInterpreter, frame::InferenceState)

+    interp.depth -= 1
+    print_rails(io, depth)
+    printstyled(io, "└─→ "; color = RAIL_COLORS[(depth+1)%N_RAILS+1])
+    result = frame.result.result
+    isa(result, InferenceState) || printstyled(io, result; color = :cyan)
+    println(io, " (", join(filter(!isnothing, (linfo, ret ? nothing : "in cycle", "$sec sec")), ", "), ')')
+
     return ret
 end

+function is_constant_propagated(frame::InferenceState)
+    return !frame.cached && CC.any(frame.result.overridden_by_const)
+end
+
+get_file_line(linfo::MethodInstance) = begin
+    def = linfo.def
+    isa(def, Method) && return def.file, Int(def.line)
+    # top-level
+    src = linfo.uninferred::CodeInfo
+    return get_file_line(first(src.linetable::Vector)::LineInfoNode)
+end
+get_file_line(lin::LineInfoNode)     = lin.file, lin.line
+
+const RAIL_COLORS = (
+    # preserve yellow for future performance linting
+    45, # light blue
+    123, # light cyan
+    150, # ???
+    215, # orange
+    231, # white
+)
+const N_RAILS = length(RAIL_COLORS)
+
+printlnstyled(args...; kwarg...) = printstyled(args..., '\n'; kwarg...)
+
+function print_rails(io, depth)
+    for i = 1:depth
+        color = RAIL_COLORS[i%N_RAILS+1]
+        printstyled(io, '│'; color)
+    end
+end
+
 function CC.finish!(interp::XInterpreter, caller::InferenceResult)
     ret = @invoke finish!(interp::AbstractInterpreter, caller::InferenceResult)
```
```julia
# Revise.jl will be automatically loaded, so no need to load it manually
julia> @enter_call sin(10)
┌ @ MethodInstance for sin(::Int64) math.jl:1218
│┌ @ MethodInstance for float(::Int64) float.jl:269
││┌ @ MethodInstance for AbstractFloat(::Int64) float.jl:243
│││┌ @ MethodInstance for Float64(::Int64) float.jl:146
│││└─→ Float64 (MethodInstance for Float64(::Int64), 1.623220734080384e9 sec)
││└─→ Float64 (MethodInstance for AbstractFloat(::Int64), 1.623220734079916e9 sec)
│└─→ Float64 (MethodInstance for float(::Int64), 1.623220734078995e9 sec)
│┌ @ MethodInstance for sin(::Float64) special/trig.jl:29
││┌ @ MethodInstance for abs(::Float64) float.jl:524
││└─→ Float64 (MethodInstance for abs(::Float64), 1.623220734082511e9 sec)
││# ... some call graph
││└─→ Float64 (MethodInstance for Base.Math.cos_kernel(::Base.Math.DoubleFloat64), 1.623220736645189e9 sec)
│└─→ Float64 (MethodInstance for sin(::Float64), 1.623220734082083e9 sec)
└─→ Float64 (MethodInstance for sin(::Int64), 1.623220733430176e9 sec)
XResult(XInterpreter(3763879814251570543), InferenceFrame(sin(::Int64) => Float64))
```
Boon !

Likely, we can hook into every method defined in `Core.Compiler` that is overloaded on `AbstractInterpreter`.
As an one more example, we can inspect `IRCode` (intermediate IR representation of Julia-level optimization) like this way:
```diff
diff --git a/src/optimize.jl b/src/optimize.jl
index 735c4ad..03d2c64 100644
--- a/src/optimize.jl
+++ b/src/optimize.jl
@@ -27,5 +27,9 @@ end
 function CC.optimize(interp::XInterpreter, opt::OptimizationState, params::OptimizationParams, @nospecialize(result))
     ret = @invoke optimize(interp::AbstractInterpreter, opt::OptimizationState, params::OptimizationParams, @nospecialize(result))

+    push!(irs, opt.ir)
+
     return ret
 end
+
+irs = OptimizationState[]
```
```julia
julia> @enter_call sin(10)
XResult(XInterpreter(3763879814251570543), InferenceFrame(sin(::Int64) => Float64))

julia> XCompiler.irs[1]
146 1 ─ %1 = Base.sitofp(Float64, _2)::Float64                                                                                                                                                                               │
    └──      return %1
``

## Pipeline Configurations

`@enter_call` and `enter_call` can accept any of parameters of `InferenceParams` or `OptimizationParams`.
```julia
julia> @enter_call ipo_constant_propagation=true rand(1:10) # enable constant propagation (default)
XResult(XInterpreter(3763879814251570543), InferenceFrame(rand(::UnitRange{Int64}) => Int64))

julia> @enter_call ipo_constant_propagation=false rand(1:10) # disable constant propagation
XResult(XInterpreter(6343901954784078298), InferenceFrame(rand(::UnitRange{Int64}) => Union{Int64, UInt64})) # looser return type inference
```

`@enter_call` and `enter_call` can also accept additional pipeline configurations:
```julia
CC.may_optimize(interp::XInterpreter)      = interp.optimize
CC.may_compress(interp::XInterpreter)      = interp.compress
CC.may_discard_trees(interp::XInterpreter) = interp.discard_trees
CC.verbose_stmt_info(interp::XInterpreter) = interp.verbose_stmt_info
```
```julia
julia> @enter_call optimize=false rand(1:10) # skip the optimization passes
```

As seen in the `ipo_constant_propagation` example, `XCompiler`'s global code cache is associated with the identity of those configurations above,
so we don't need to care about the previous compilation cache with different parameters.

## Cache

`XCompiler` keeps its own code cache, and `@enter_call` never interacts with Julia's code execution (e.g. `@enter_call enter_call(sin, (Int,))` won't influence _any code required to run `XCompiler`_).
We can manually inspect stored code cache like this:
```julia
julia> (; interp, frame) = @enter_call sin(10)
XResult(XInterpreter(3763879814251570543), InferenceFrame(sin(::Int64) => Float64))

julia> XCompiler.X_CODE_CACHE[interp.cache_key]
IdDict{Core.MethodInstance, Core.CodeInstance} with 228 entries:
  MethodInstance for promote_type(::Type{Int128}, ::Type{Int64})                              => CodeInstance(MethodInstance for promote_type(::Type{Int128}, ::Type{Int64}), #undef, 0x00000000000016aa, 0xffffffff…
  MethodInstance for Base.promote_typeof(::UInt32, ::UInt16)                                  => CodeInstance(MethodInstance for Base.promote_typeof(::UInt32, ::UInt16), #undef, 0x00000000000016ac, 0xffffffffffff…
  MethodInstance for Base._promote(::Int64, ::Irrational{:π})                                 => CodeInstance(MethodInstance for Base._promote(::Int64, ::Irrational{:π}), #undef, 0x0000000000003d33, 0xfffffffffff…
  MethodInstance for &(::UInt64, ::UInt64)                                                    => CodeInstance(MethodInstance for &(::UInt64, ::UInt64), #undef, 0x0000000000000001, 0xffffffffffffffff, UInt64, #und…
  # ...
```

Here `CodeInstance` (holding a final result of Julia-level optimization) is stored with the associated `MethodInstance` key (which is the unit of inter-procedural Julia's inference/optimization), as Julia's native code generation pipeline does.

Revise.jl is integrated with `XCompiler`'s global code cache.
It means, `XCompiler` will invalidate all the global cache each time when Revise.jl updates `XCompiler`'s code, so that the next `enter_call` runs pipeline without influenced by the caches generated with the old code in anyway.

## TODO

- [ ] implement something to automatically generate those overloads given the definitions of `Core.Compiler`
