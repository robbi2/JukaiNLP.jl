const shift = 1
const reducel = 2
const reducer = 3

abstract Model

type State
    step::Int
    score::Float64
    top::Int
    left::Nullable{State}
    right::Int
    lc::Int
    rc::Int
    tokens::Vector{Token}
    model::Model
    prev::State
    prevact::Int
    feat::Vector{Int}

    function State(step, score, top, left, right, lc, rc, tokens, model)
        new(step, score, top, left, right, lc, rc, tokens, model)
    end

    function State(step, score, top, left, right, lc, rc, tokens, model, prev, prevact)
        new(step, score, top, left, right, lc, rc, tokens, model, prev, prevact)
    end

end

function State{M<:Model}(tokens::Vector{Token}, model::M)
    State(1, 0.0, 0, Nullable{State}(), 1, -1, -1, tokens, model)
end

function stack2array(s::State)
    st = s
    res = Int[]
    while !isnull(st.left)
        unshift!(res, st.top)
        st = get(st.left)
    end
    unshift!(res, st.top)
    res
end

# prints [ a/NN b/VB ][ c/NN d/PP ]
function Base.print(io::IO, s::State)
    stack = map(stack2array(s)) do i
        i == 0 ? "ROOT/ROOT" :
        id2word[s.tokens[i].word] * "/" * id2tag[s.tokens[i].tag]
    end
    stack = join(stack, " ")
    buffer = map(s.right:length(s.tokens)) do i
        id2word[s.tokens[i].word] * "/" * id2tag[s.tokens[i].tag]
    end 
    buffer = join(buffer, " ")
    print(io, "[", stack, "][", buffer, "]")
end


function stacktrace(io::IO, s::State)
    ss = state2array(s)
    for i in 1:length(ss)
        act = ss[i].prevact == 1 ? "SHIFT" :
              ss[i].prevact == 2 ? "REDUCER" :
              ss[i].prevact == 3 ? "REDUCEL" :
              throw("Invalid action: $(ss[i].prevact).")
        i > 1 && println(io, act)
        println(io, ss[i])
    end
end
stacktrace(s::State) = stacktrace(STDOUT, s)

function toconll(io::IO, s::State)
    pred = heads(s)
    for i in 1:length(s.tokens)
        t = s.tokens[i]
        items = [i, id2word[t.word], "-", id2tag[t.tag],
                    pred[i], t.head, id2label[t.label]]
        println(io, join(items, "\t"))
    end
    println(io, "")
end
toconll(s::State) = conll(STDOUT, s)

# to retrieve result
function heads(s::State)
    @assert isfinal(s)
    res = fill(-1, length(s.tokens))
    st = s
    while isdefined(st, :prev)
        st.lc >= 0 && ( res[st.lc] = st.top )
        st.rc >= 0 && ( res[st.rc] = st.top )
        st = st.prev
    end
    @assert all(h -> h >= 0, res)
    res
end

###################################################
#################### "expand"s ####################
###################################################

function transit(s::State, act::Int, top::Int, left::Nullable{State}, right::Int, lc::Int, rc::Int)
    State(s.step + 1, s.score + s.model(s, act),
          top, left, right, lc, rc, s.tokens, s.model, s, act)
end

function expand(s::State, act::Int)
    if act == shift
        return transit(s, act, s.right, Nullable{State}(s), s.right+1, -1, -1)
    elseif act == reducel
        left = get(s.left)
        return transit(s, act, s.top, left.left, s.right, left.top, s.rc)
    elseif act == reducer
        left = get(s.left)
        return transit(s, act, left.top, left.left, s.right, left.lc, s.top)
    else
        throw("Invalid action: $(act).")
    end
end

tokenat(s::State, i::Int) = get(s.tokens, i, rootword)

# check if buffer is empty
bufferisempty(s::State) = s.right > length(s.tokens)

# check if can perform Reduce, that is, length(stack) >= 2
reducible(s::State) = !isnull(s.left)

# check if the state is final state
isfinal(s::State) = bufferisempty(s) && !reducible(s)

function expandpred(s::State)
    isfinal(s) && return []
    res = State[]
    if reducible(s)
        push!(res, expand(s, reducer))
        if get(s.left).top != 0
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
        s1 = tokenat(s, get(s.left).top)
        if s1.head == s.top
            return [expand(s, reducel)]
        elseif s0.head == get(s.left).top
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

function featuregen(s::State)
    n0i = bufferisempty(s) ? 0 : s.right
    n0  = tokenat(s, n0i)
    n1  = tokenat(s, n0i == 0 ? 0 : n0i+1)
    s0  = tokenat(s, s.top)
    s0l, s0r = tokenat(s, s.lc), tokenat(s, s.rc)
    if isnull(s.left)
        s1, s2, s1l, s1r = rootword, rootword, rootword, rootword
    else
        left = get(s.left)
        s1 = tokenat(s, left.top)
        s2 = tokenat(s, isnull(left.left) ? 0 : get(left.left).top)
        s1l, s1r = tokenat(s, left.lc), tokenat(s, left.rc)
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
