const SHIFT = 1
const REDUCEL = 2
const REDUCER = 3

# calculates action id for labeled reduce
# even numbers >= 2
reducel(label::Int) = label << 1
reducel() = REDUCEL

 # odd numbers >= 3
reducer(label::Int) = (label << 1) | 1
reducer() = REDUCER

# retrieve action type 1, 2 or 3
acttype(action::Int) = action == 1 ? SHIFT : 2 + (action & 1)

# retrieve label id
tolabel(action::Int) = action >> 1

type State{T <: ParserType}
    step::Int
    score::Float64
    top::Int
    right::Int
    left::State{T}
    lchild::State{T}
    rchild::State{T}
    lsibl::State{T}
    rsibl::State{T}
    tokens::Vector{Token}
    parser::DepParser
    prev::State{T}
    prevact::Int
    feat::Vector{Int}
    beamid::Int
    batchid::Int

    function State(step, score, top, right)
        new(step, score, top, right)
    end

    function State(step, score, top, right, left,
        lchild, rchild, lsibl, rsibl, tokens, parser, prev, prevact)
        new(step, score, top, right, left,
            lchild, rchild, lsibl, rsibl, tokens, parser, prev, prevact)
    end
end

# nullstate is a State object whose all State type fields
# reference itself. used instead of Nullable{State} or nothing::Void
let
    function __nullstate__(T::Type)
        s = State{T}(0, 0.0, 0, 1)
        s.left, s.lchild, s.rchild = s, s, s
        s.lsibl, s.rsibl, s.prevact = s, s, reducel(1) # reducel(NONE)
        return s
    end
    const __labeled = __nullstate__(Labeled)
    const __unlabeled = __nullstate__(Unlabeled)
    global nullstate
    nullstate(::Type{Labeled}) = __labeled
    nullstate(::Type{Unlabeled}) = __unlabeled
end

Base.isnull(s::State) = s.step == 0

function State{T}(tokens::Vector{Token}, parser::DepParser{T})
    State{T}(1, 0.0, 0, 1, nullstate(T), nullstate(T), nullstate(T),
        nullstate(T), nullstate(T), tokens, parser, nullstate(T), reducel(1))
end

# to retrieve result
function heads(s::State)
    @assert isfinal(s)
    res = fill(-1, length(s.tokens))
    st = s
    while !isnull(st.prev)
        !isnull(st.lchild) && ( res[st.lchild.top] = st.top )
        !isnull(st.rchild) && ( res[st.rchild.top] = st.top )
        st = st.prev
    end
    @assert all(h -> h >= 0, res)
    res
end

function labels(s::State)
    @assert isfinal(s)
    res = fill(-1, length(s.tokens))
    st = s
    while !isnull(st.prev)
        atype = acttype(st.prevact)
        atype == REDUCEL && ( res[st.lchild.top] = tolabel(st.prevact) )
        atype == REDUCER && ( res[st.rchild.top] = tolabel(st.prevact) )
        st = st.prev
    end
    @assert all(l -> l >= 0, res)
    res
end

tokenat(s::State, i::Int) = get(s.tokens, i, roottoken)
tokenat(s::State, t::State) = get(s.tokens, t.top, roottoken)

function labelat(s::State, child::State)
    st = s
    while st.step != child.step + 1
        isnull(st.prev) && break
        st = st.prev
    end
    tolabel(st.prevact)
end

function expand{T}(s::State{T}, act::Int)
    atype = acttype(act)
    top, right, left, lchild, rchild, lsibl, rsibl = begin
        if atype == SHIFT
             s.right, s.right+1, s, nullstate(T), nullstate(T), nullstate(T), nullstate(T)
        elseif atype == REDUCEL
             s.top, s.right, s.left.left, s.left, s.rchild, s, s.rsibl
        elseif atype == REDUCER
             s.left.top, s.right, s.left.left, s.left.lchild, s, s.left.lsibl, s.left
        else
            throw("Invalid action: $(act).")
        end
    end
    score = s.parser.model(s, act)
    State{T}(s.step+1, score, top, right, left, lchild,
        rchild, lsibl, rsibl, s.tokens, s.parser, s, act)
end

# check if buffer is empty
bufferisempty(s::State) = s.right > length(s.tokens)

# check if can perform Reduce, that is, length(stack) >= 2
reducible(s::State) = !isnull(s.left)

# check if the state is final state
isfinal(s::State) = bufferisempty(s) && !reducible(s)

function isvalid(s::State, act::Int)
    if act == SHIFT
        return !bufferisempty(s)
    elseif act == REDUCEL
        return reducible(s) && s.left.top != 0
    elseif act == REDUCER
        return reducible(s)
    else
        throw("invalid action: $act")
    end
end

function expand_reduce_state!(res::Vector{State{Labeled}}, s::State{Labeled}, act::Function)
    for label in 1:length(s.parser.labels)
        push!(res, expand(s, act(label)))
    end
end

function expand_reduce_state!(res::Vector{State{Unlabeled}}, s::State{Unlabeled}, act::Function)
    push!(res, expand(s, act()))
end

function expandpred{T}(s::State{T})
    isfinal(s) && return []
    res = State{T}[]
    if reducible(s)
        expand_reduce_state!(res, s, reducer)
        if s.left.top != 0
            expand_reduce_state!(res, s, reducel)
        end
    end
    bufferisempty(s) || push!(res, expand(s, SHIFT))
    res
end

function expand_reduce_state(s::State{Unlabeled}, act::Function)
    expand(s, act())
end

function expand_reduce_state(s::State{Labeled}, act::Function)
    child = act == reducel ? s.left.top :
            act == reducer ? s.top :
            throw("Action must be reduce")
    expand(s, act(tokenat(s, child).label))
end

function expandgold{T}(s::State{T})
    isfinal(s) && return []
    if !reducible(s)
        return [expand(s, SHIFT)]
    else
        s0 = tokenat(s, s)
        s1 = tokenat(s, s.left)
        if s1.head == s.top
            return [expand_reduce_state(s, reducel)]
        elseif s0.head == s.left.top
            if all(i -> tokenat(s, i).head != s.top, s.right:length(s.tokens))
                return [expand_reduce_state(s, reducer)]
            end
        end
    end
    return [expand(s, SHIFT)]
end
