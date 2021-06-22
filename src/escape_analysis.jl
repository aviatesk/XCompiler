using Core: ReturnNode, SSAValue

function escape_analysis(ir::IRCode, ci::CodeInfo)
    # escape_info = IdDict{Tuple{Any, Any}, Vector{Any}}()

    # Stage 1:
    # compute each block's alloc and escapes in reverse order
    # the dictionary constructs a mapping from bb to alloc/escapes
    # TODO: replace Vector with Set
    block_alloc = IdDict{Int, Set}()
    block_escape = IdDict{Int, Set}()

    for (idx, block) in enumerate(ir.cfg.blocks)
        start = block.stmts.start
        stop = block.stmts.stop
        alloc = Set{Expr}()
        escape = Set{Union{Expr, SSAValue}}()
        for idx = stop:-1:start
            stmt = ir.stmts[idx][:inst]
            # if a stmt is already marked as an escape
            # then every args of it should be marked as escape as well
            # in this way we propagate the escape information

            # TODO: this will not pass compilation
            if stmt in escape
                if isa(stmt, Expr)
                    # escape = vcat(escape, args[2:end])
                end
                # TODO: any missing cases other than expr?
            else
                if isa(stmt, Expr) && stmt.head === :call
                    # special handle calls
                    f = stmt.args[1]
                    typ = argextype(f, ir, ir.sptypes)
                    # TODO: identify call to mutable struct's constructor and add to alloc
                    # push!(alloc, stmt)
                    # TODO: (else branch) call to any other functions, mark args as escape
                    # alloc = vcat(alloc, args[2:end])
                elseif isa(stmt, ReturnNode) && isdefined(stmt, :val)
                    push!(escape, stmt.val)
                end
            end
        end
        block_alloc[idx] = alloc
        block_escape[idx] = escape
    end

    # Stage 2:
    # compute before and after of all blocks using worklist
    before = IdDict{Int, Set}()
    after = IdDict{Int, Set}()
    worklist = Vector{Int}(range(1, length(ir.cfg.blocks)))
    workset = Set{Int}(range(1, length(ir.cfg.blocks)))
    while !isempty(worklist)
        idx = popfirst!(worklist)
        setdiff!(workset, [idx])
        new_before = Set{Any}()
        block = ir.cfg.blocks[idx]
        if !isempty(block.preds)
            for pred_idx in block.preds
                union!(new_before, after[pred_idx])
            end
        end
        before[idx] = new_before
        new_after = union(new_before, block_escape[idx])
        if new_after != after[idx]
            for succ_idx in block.succs
                if !succ_idx in workset
                    push!(worklist, succ_idx)
                    union!(workset, [succ_idx])
                end
            end
        end
        after[idx] = new_after
    end
    # dummy return to ensure it pass compilation
    return ir
end
