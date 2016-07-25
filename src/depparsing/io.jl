
function state2array(s::State)
    st = s
    res = State[]
    while !isnull(st.prev)
        unshift!(res, st)
        st = st.prev
    end
    unshift!(res, st)
    res
end

function stack2array(s::State)
    st = s
    res = Int[]
    while !isnull(st.left)
        unshift!(res, st.top)
        st = st.left
    end
    unshift!(res, st.top)
    res
end

# prints [ a/NN b/VB ][ c/NN d/PP ]
function Base.print(io::IO, parser:: DepParser, s::State)
    stack = map(stack2array(s)) do i
        i == 0 ? "ROOT/ROOT" :
        getkey(parser.words, s.tokens[i].word) * "/" *
        getkey(parser.tags, s.tokens[i].tag)
    end
    stack = join(stack, " ")
    buffer = map(s.right:length(s.tokens)) do i
        getkey(parser.words, s.tokens[i].word) * "/" *
        getkey(parser.tags, s.tokens[i].tag)
    end 
    buffer = join(buffer, " ")
    print(io, "[", stack, "][", buffer, "]")
end

function actstr(s::State{Labeled})
    act = s.prevact
    labels(id) = getkey(s.parser.labels, id)
    return acttype(act) == SHIFT ? "shift" :
           acttype(act) == REDUCEL ? "reducel($(labels((tolabel(act)))))" :
           acttype(act) == REDUCER ? "reducer($(labels((tolabel(act)))))" :
           throw("Invalid action: $(act).")
end

function actstr(s::State{Unlabeled})
    act = s.prevact
    return acttype(act) == SHIFT ? "shift" :
           acttype(act) == REDUCEL ? "reducel" :
           acttype(act) == REDUCER ? "reducer" :
           throw("Invalid action: $(act).")
end

function stacktrace{T}(io::IO, parser::DepParser, s::State{T})
    ss = state2array(s)
    for i in 1:length(ss)
        i > 1 && println(io, actstr(ss[i]))
        print(io, parser, ss[i])
        println(io)
    end
end
stacktrace(parser::DepParser, s::State) = stacktrace(STDOUT, parser, s)

function toconll(io::IO, parser::DepParser, s::State)
    pred = heads(s)
    for i in 1:length(s.tokens)
        t = s.tokens[i]
        items = [i, getkey(parser.words, t.word), "-",
                    getkey(parser.tags, t.tag), pred[i],
                    t.head, getkey(parser.labels, t.label)]
        println(io, join(items, "\t"))
    end
    println(io, "")
end
toconll(parser::DepParser, s::State) = toconll(STDOUT, parser, s)

