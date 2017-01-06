module ShowEach

export @showeach, gather_stdout, set_loop_limit, reset_indent

@enum Position Top TopFunction Middle MiddleFunction

const origSTDOUT = STDOUT

const CompactIO = (IOContext(origSTDOUT, limit=true, compact=true, displaysize=(10,20)))

type PrintState
    level::Int
    pos::Vector{Position}
    count::Vector{Int}
    loop_limit::Int
    redirect::Bool
    io::IO    # Does this matter for performance?
end

#PrintState{T<:IO}(level, pos, redirect, io::T) = PrintState{T}(level, pos, redirect, io)

const state = PrintState(0, [], [], 6, false, STDOUT)

inc(pos::Position) = (state.level += 1; push!(state.pos, pos); push!(state.count, 0))
inc() = inc(Top)
dec() = (state.level -= 1; pop!(state.pos); pop!(state.count))

inc_counter() = (state.level > 0 && state.pos[end] != MiddleFunction &&  (state.count[end] += 1))

isloop() = (state.level > 0 && any(state.count .>= state.loop_limit))

function reset_indent()
    state.level = 0
    state.pos = []
    state.count = []
end

gather_stdout(b::Bool) = (reset_indent(); state.redirect = b)
set_loop_limit(n::Int) = (reset_indent(); state.loop_limit = n)

function indent_all_but_top()
    ret = ""
    for (i, pos) in enumerate(state.pos[1:end-1])
        if pos == Middle
            ret = ret*"│  "
        else
            ret = ret*"   "
        end
    end
    ret
end


function indent(str::String)
    ret = indent_all_but_top()
    if state.level == 0 || state.pos[end] in [TopFunction, MiddleFunction]
        return ret*"   "*str
    else
        return ret*"│  "*str
    end
end


function indent()
    ret = indent_all_but_top()
    if state.level > 0
        if state.pos[end] == Top
            ret = ret*"┌─ "
            state.pos[end] = Middle
        elseif state.pos[end] == TopFunction
            ret = ret*"   "
            state.pos[end] = MiddleFunction
        elseif state.pos[end] == MiddleFunction
            ret = ret*"   "
        else
            inc_counter()
            ret = ret*"├─ "
        end
    end
    return ret
end


function show_in_tree(expr::String, value)
    if !isloop()
        value_repr = IOBuffer()
        show(IOContext(value_repr, CompactIO), "text/plain", value)
        l = length(expr) + 3
        output = replace(String(value_repr), "\n", "\n"*indent(" "^l))
        println(state.io, indent(), expr, " = ", output)
        if isloop()
            println(state.io, indent(), " ⋮")
        end
    else
        nothing
    end
end


function show_vector_short(io::IO, v, opn, cls)
    compact, prefix = Base.array_eltype_show_how(v)
    limited = get(io, :limit, false)
    if compact && !haskey(io, :compact)
        io = IOContext(io, :compact => compact)
    end
    print(io, prefix)
    if limited && length(v) > 6
        inds = Base.indices1(v)
        Base.show_delim_array(io, v, opn, ",", "", false, inds[1], inds[1]+2)
        print(io, "  \u2026  ")
        Base.show_delim_array(io, v, "", ",", cls, false, inds[end-2], inds[end])
    else
        Base.show_delim_array(io, v, opn, ",", cls, false)
    end
end


function show_in_tree(expr::String, value::Vector)
    if !isloop()
        value_repr = IOBuffer()
        show_vector_short(IOContext(value_repr, CompactIO), value, "[", "]")
        l = length(expr) + 3
        output = replace(String(value_repr), "\n", "\n"*indent(" "^l))
        println(state.io, indent(), expr, " = ", output)
        if isloop()
            println(state.io, indent(), " ⋮")
        end
    else
        nothing
    end
end


function showexpr(expr, newexpr)
    :(inc(); value = ($newexpr); dec(); show_in_tree($(string(expr)), value); value)
end



function showeach_func(expr::Expr)
    new_inner_body = Expr(:block, :(isloop() || (idt = indent(); isloop() ? println(state.io, indent(), " ⋮") : println(state.io, idt, "in function ", $(string(expr.args[1])), ":"))), :(inc(TopFunction)), (showeach(e) for e in expr.args[2:end])...)
    new_inner_body =  temporary_redirect_stdout(new_inner_body, "function "*string(expr.args[1]))
    new_body = :(try $(new_inner_body) finally dec() end)
    return Expr(expr.head, esc(expr.args[1]), :($new_body))
end


function is_function_definition(expr::Expr)
    expr.head == :function ||
    (
        expr.head == :(=) &&
        (
            Meta.isexpr(expr.args[1], :call) ||
            (
                Meta.isexpr(expr.args[1], :(::)) && Meta.isexpr(expr.args[1].args[1], :call)
            )
        )
    )
end


function showeach(expr::Expr)
    if is_function_definition(expr)
        # function definition -> show body on function call
        return showeach_func(expr)
    elseif expr.head in [:block, :vect, :tuple, :vcat, :hcat, :row, :(:), :(...), :flatten, :return, :if, :generator, :filter]
        # show all arguments recursively
        return Expr(expr.head, (showeach(e) for e in expr.args)...)
    elseif expr.head in [:(=), :(+=), :(-=), :(*=), :(/=), :typed_vcat, :typed_hcat]
        # show all argument but the first recursively
        return Expr(expr.head, esc(expr.args[1]), (showeach(e) for e in expr.args[2:end])...)
    elseif expr.head in [:ref, :comprehension, :(&&), :(||)]
        # show expression and all arguments recursively
        newexpr = Expr(expr.head, (showeach(e) for e in expr.args)...)
        return showexpr(expr, newexpr)
    elseif  expr.head in [:call, :., :typed_comprehension]
        # show expression and all arguments but the first recursively
        newexpr = Expr(expr.head, esc(expr.args[1]), (showeach(e) for e in expr.args[2:end])...)
        return showexpr(expr, newexpr)
    elseif expr.head in [:for, :while]
        # show the kind of loop and all arguments recursively
        newexpr = Expr(expr.head, (showeach(e) for e in expr.args)...)
        return showexpr(string(expr.head) * " ... end", newexpr)
    elseif expr.head == :comparison
        # show expression and every odd argument
        newexpr = Expr(expr.head, (isodd(i) ? showeach(e) : esc(e) for (i,e) in enumerate(expr.args))...)
        return showexpr(expr, newexpr)
    else
        # just return the expression unchanged
        return esc(expr)
    end
end


showeach(e::Symbol) = :(value = $(esc(e)); show_in_tree($(string(e)), value); value)
showeach(e) = esc(e)


function temporary_redirect_stdout(expr, name = nothing)
    if state.redirect
        if name == nothing
            text = "gathered STDOUT:"
        else
            text = "STDOUT from $name:"
        end
        return quote
            if STDOUT == origSTDOUT
                (rd, wr) = redirect_stdout()
                value = begin $(expr) end
                print(" ") # work around blocking of `readavailable` for empty pipe
                close(wr)
                output = chop(String(readavailable(rd)))
                close(rd)
                redirect_stdout($origSTDOUT)
                if length(output) > 0
                    println($text)
                    print(String(output))
                end
                value
            else
                tmpSTDOUT = STDOUT
                (rd, wr) = redirect_stdout()
                value = begin $(expr) end
                print(" ") # work around blocking of `readavailable` for empty pipe
                close(wr)
                output = chop(String(readavailable(rd)))
                close(rd)
                redirect_stdout(tmpSTDOUT)
                if length(output) > 0
                    println($text)
                    print(String(output))
                end
                value
            end
        end
    else
        return expr
    end
end


macro showeach(expr)
    temporary_redirect_stdout(showeach(expr))
end


end # module
