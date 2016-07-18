const shift = 1
const reducel = 2
const reducer = 3

abstract Model

typealias Head Int # token index
typealias Dir Int  # Left, Right, Head
typealias Order Int # Nth Left, Mth Right ..
const L = 1
const R = 2
const H = 3
const maxdir   = 3
const maxorder = 2

context(h::Head, d::Dir, o::Order) = (h+1) * maxdir * maxorder + d * maxorder + o

function initedges(sent::Sent)
    fill(-1, (length(sent)+1)*maxdir*maxorder+maxdir*maxorder+maxorder)
end

type State
    step::Int
    score::Float64
    s0::Int
    b0::Int
    lc::Int
    rc::Int
    tokens::Vector{Token}
    model::Model
    prev::State
    prevact::Int
    feat::Vector{Int}

    function State(step, score, stack, buffer, edges, sent, model)
        new(step, score, stack, buffer, edges, sent, model)
    end
end

function State{M<:Model}(sent::Vector{Token}, model::M)
    State(1, zero(Float),  # step, #score
          Int[0],         # stack with root
          1,                       # buffer
          initedges(sent),         # edges
          sent, model)             # sent, model
end

function next(s::State, action::Int)
    State(s.step + 1,                   # step
          s.score + s.model(s, action), #score
          copy(s.stack),                #stack
          s.buffer,                     #buffer
          copy(s.edges),                #edges
          s.sent, s.model, s,            #sent, #model #prev
          int(action))                  #prevact
end

# prints [ a/NN b/VB ][ c/NN d/PP ]
function Base.print(io::IO, s::State)
    stack = map(s.stack) do i
        i == 0 ? "ROOT/ROOT" :
        s.sent[i].wordstr * "/" * s.sent[i].tagstr
    end |> reverse |> x -> join(x," ")
    buffer = map(s.buffer) do i
        s.sent[i].wordstr * "/" * s.sent[i].tagstr
    end |> x -> join(x, " ")
    print(io, "[", stack, "][", buffer, "]")
end


function stacktrace(io::IO, s::State)
    ss = state2array(s)
    println(io, ss[1])
    for i in 2:length(ss)
        println(io, act(ss[i].prevact))
        println(io, ss[i])
    end
end
stacktrace(s::State) = stacktrace(STDOUT, s)

function toconll(io::IO, s::State)
    pred = heads(s)
    for i in 1:length(s.sent)
        println(io, i, "\t", s.sent[i], "\t", pred[i])
    end
    println(io, "")
end
conll(s::State) = conll(STDOUT, s)

# to retrieve result
heads(s::State) = map(i->s.edges[context(i,H,1)], 1:length(s.sent))
hashead(s::State, i::Int) = s.edges[context(i,H,1)] != -1

###################################################
#################### "expand"s ####################
###################################################

function expand(s::State, act::Int)
    if act == shift
    elseif act == reducel
    elseif act == reducer
    else
        throw("Invalid action: $(act).")
    end

    s = next(s, action)
    s0i = shift!(s.stack)
    s1i = shift!(s.stack)
    unshift!(s.stack, s0i)
    s.edges[context(s0i,L,2)] = s.edges[context(s0i,L,1)]
    s.edges[context(s1i,H,2)] = s.edges[context(s0i,H,1)]
    s.edges[context(s0i,L,1)] = s1i
    s.edges[context(s1i,H,1)] = s0i
    return s
end

#=
function expand(s::State, action::Type{RightArc})
    s   = next(s, action)
    s0i = shift!(s.stack)
    s1i = s.stack[1]
    s.edges[context(s1i,R,2)] = s.edges[context(s1i,R,1)]
    s.edges[context(s0i,H,2)] = s.edges[context(s1i,H,1)]
    s.edges[context(s1i,R,1)] = s0i
    s.edges[context(s0i,H,1)] = s1i
    return s
end

function expand(s::State, action::Type{Shift})
    s   = next(s, action)
    n0i = s.buffer
    s.buffer += 1
    unshift!(s.stack, n0i)
    return s
end
=#

bufferisempty(s::State) = s.buffer > length(s.sent)

isvalid(s::State, ::Type{LeftArc}) = length(s.stack) >= 2 && s.stack[2] != 0
isvalid(s::State, ::Type{RightArc}) = length(s.stack) >= 2
isvalid(s::State, ::Type{Shift}) = !bufferisempty(s)

isgold(s::State, ::Type{LeftArc}) = isvalid(s, LeftArc)  && s.sent[s.stack[2]].head == s.stack[1]
isgold(s::State, ::Type{RightArc}) = isvalid(s, RightArc) && s.sent[s.stack[1]].head == s.stack[2] && all(i -> s.sent[i].head != first(s.stack), s.buffer:length(s.sent))
isgold(s::State, ::Type{Shift}) = isvalid(s, Shift)

isfinal(s::State) = bufferisempty(s) && length(s.stack) == 1

function expandpred(s::State)
    isfinal(s) && return []
    res = State[]
    isvalid(s, LeftArc)  && push!(res, expand(s, LeftArc))
    isvalid(s, RightArc) && push!(res, expand(s, RightArc))
    isvalid(s, Shift)    && push!(res, expand(s, Shift))
    return res
end

function expandgold(s::State)
    isfinal(s) && return []
    isgold(s, LeftArc)  && return [expand(s, LeftArc)]
    isgold(s, RightArc) && return [expand(s, RightArc)]
    isgold(s, Shift)    && return [expand(s, Shift)]
    stacktrace(s)
    throw("NO ACTION TO PERFORM")
end

###################################################
################## feature function ###############
###################################################

ind2word(s::State, i::Int) = get(s.sent, i, rootword)

function featuregen(s::State)
    stack = s.stack
    stacklen = length(stack)
    s0i = stacklen < 1 ? 0 : stack[1]
    s1i = stacklen < 2 ? 0 : stack[2]
    s2i = stacklen < 3 ? 0 : stack[3]
    n0i = bufferisempty(s) ? 0 : s.buffer
    s0  = ind2word(s, s0i)
    s1  = ind2word(s, s1i)
    s2  = ind2word(s, s2i)
    n0  = ind2word(s, n0i)
    n1  = ind2word(s,  n0i+1)
    s0l  = ind2word(s, s.edges[context(s0i,L,1)])
    s0r  = ind2word(s, s.edges[context(s0i,R,1)])
    s1l  = ind2word(s, s.edges[context(s1i,L,1)])
    s1r  = ind2word(s, s.edges[context(s1i,R,1)])

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
