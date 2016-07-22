const shift = 1
const reducel = 2
const reducer = 3

abstract Model

type State
    step::Int
    score::Float64
    top::Int
    right::Int
    left
    lchild
    rchild
    lsibl
    rsibl
    tokens::Vector{Token}
    model::Model
    prev::State
    prevact::Int
    feat::Vector{Int}

    function State(step, score, top, right, left,
        lchild, rchild, lsibl, rsibl, tokens, model)
        new(step, score, top, right, left,
            lchild, rchild, lsibl, rsibl, tokens, model)
    end

    function State(step, score, top, right, left,
        lchild, rchild, lsibl, rsibl, tokens, model, prev, prevact)
        new(step, score, top, right, left,
            lchild, rchild, lsibl, rsibl, tokens, model, prev, prevact)
    end

end

function State{M<:Model}(tokens::Vector{Token}, model::M)
    State(1, 0.0, 0, 1, nothing, nothing,
        nothing, nothing, nothing, tokens, model)
end

# to retrieve result
function heads(s::State)
    @assert isfinal(s)
    res = fill(-1, length(s.tokens))
    st = s
    while isdefined(st, :prev)
        st.lchild != nothing && ( res[st.lchild.top] = st.top )
        st.rchild != nothing && ( res[st.rchild.top] = st.top )
        st = st.prev
    end
    @assert all(h -> h >= 0, res)
    res
end

tokenat(s::State, i::Int) = get(s.tokens, i, rootword)
tokenat(s::State, t::State) = get(s.tokens, t.top, rootword)
tokenat(s::State, ::Void) = rootword

###################################################
#################### "expand"s ####################
###################################################

function transit(s::State, act::Int, top::Int,
    right::Int, left, lchild, rchild, lsibl, rsibl)
    State(s.step + 1, s.score + s.model(s, act), top, right,
        left, lchild, rchild, lsibl, rsibl, s.tokens, s.model, s, act)
end

function expand(s::State, act::Int)
    if act == shift
        return transit(s, act, s.right, s.right+1, s, nothing, nothing, nothing, nothing)
    elseif act == reducel
        return transit(s, act, s.top, s.right, s.left.left, s.left, s.rchild, s, s.rsibl)
    elseif act == reducer
        return transit(s, act, s.left.top, s.right, s.left.left, s.left.lchild, s, s.left.lsibl, s.left)
    else
        throw("Invalid action: $(act).")
    end
end

# check if buffer is empty
bufferisempty(s::State) = s.right > length(s.tokens)

# check if can perform Reduce, that is, length(stack) >= 2
reducible(s::State) = s.left != nothing

# check if the state is final state
isfinal(s::State) = bufferisempty(s) && !reducible(s)

function expandpred(s::State)
    isfinal(s) && return []
    res = State[]
    if reducible(s)
        push!(res, expand(s, reducer))
        if s.left.top != 0
            push!(res, expand(s, reducel))
        end
    end
    bufferisempty(s) || push!(res, expand(s, shift))
    res
end

function expandgold(s::State)
    isfinal(s) && return []
    if !reducible(s)
        return [expand(s, shift)]
    else
        s0 = tokenat(s, s.top)
        s1 = tokenat(s, s.left.top)
        if s1.head == s.top
            return [expand(s, reducel)]
        elseif s0.head == s.left.top
            if all(i -> tokenat(s, i).head != s.top, s.right:length(s.tokens))
                return [expand(s, reducer)]
            end
        end
    end
    return [expand(s, shift)]
end

###################################################
################## feature function ###############
###################################################

function tokenat(s::State, syms::Symbol...)
    head, tail = syms[1], syms[2:end]
    isempty(tail) && return tokenat(s, s.(head))
    tok = tokenat(s, s.(head))
    if tok.word == rootword.word
        return tok
    else
        return tokenat(s.(head), tail...)
    end
end

function featuregen(s::State)
    n0  = tokenat(s, s.right)
    n1  = tokenat(s, s.right+1)
    s0  = tokenat(s, s.top)
    s0l = tokenat(s, s.lchild)
    s0r = tokenat(s, s.rchild)
    s0l2 = tokenat(s, s.lsibl) # s0's lmost child's sibling
    s0r2 = tokenat(s, s.rsibl)
    s02l = tokenat(s, :lchild, :lchild)
    if s.left == nothing
        s1, s2, s1l, s1r = rootword, rootword, rootword, rootword
    else
        s1 = tokenat(s, s.left.top)
        s2 = tokenat(s, s.left.left)
        s1l = tokenat(s, s.left.lchild)
        s1r = tokenat(s, s.left.rchild)
    end
    len = size(s.model.weights, 1) # used in @template macro
    @template begin
        # template (1)
        (s0.word,)
        (s0.tag,)
        (s0.word, s0.tag)
        (s1.word,)
        (s1.tag,)
        (s1.word, s1.tag)
        (n0.word,)
        (n0.tag,)
        (n0.word, n0.tag)

        # additional for (1)
        (n1.word,)
        (n1.tag,)
        (n1.word, n1.tag)

        # template (2)
        (s0.word, s1.word)
        (s0.tag, s1.tag)
        (s0.tag, n0.tag)
        (s0.word, s0.tag, s1.tag)
        (s0.tag, s1.word, s1.tag)
        (s0.word, s1.word, s1.tag)
        (s0.word, s0.tag, s1.tag)
        (s0.word, s0.tag, s1.word, s1.tag)

        # additional for (2)
        (s0.tag, s1.word)
        (s0.word, s1.tag)
        (s0.word, n0.word)
        (s0.word, n0.tag)
        (s0.tag, n0.word)
        (s1.word, n0.word)
        (s1.tag, n0.word)
        (s1.word, n0.tag)
        (s1.tag, n0.tag)

        # template (3)
        (s0.tag, n0.tag, n1.tag)
        (s1.tag, s0.tag, n0.tag)
        (s0.word, n0.tag, n1.tag)
        (s1.tag, s0.word, n0.tag)

        # template (4)
        (s1.tag, s1l.tag, s0.tag)
        (s1.tag, s1r.tag, s0.tag)
        (s1.tag, s0.tag, s0r.tag)
        (s1.tag, s1l.tag, s0.tag)
        (s1.tag, s1r.tag, s0.word)
        (s1.tag, s0.word, s0l.tag)

        # template (5)
        (s2.tag, s1.tag, s0.tag)
    end
end
