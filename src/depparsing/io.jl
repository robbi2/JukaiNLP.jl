
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
function Base.print(io::IO, parser:: DepParser, s::State)
    id2word = parser.words.idkey
    id2tag = parser.tags.idkey
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


function stacktrace(io::IO, parser::DepParser, s::State)
    ss = state2array(s)
    for i in 1:length(ss)
        act = ss[i].prevact == 1 ? "SHIFT" :
              ss[i].prevact == 2 ? "REDUCER" :
              ss[i].prevact == 3 ? "REDUCEL" :
              throw("Invalid action: $(ss[i].prevact).")
        i > 1 && println(io, act)
        println(io, parser, ss[i])
    end
end
stacktrace(parser::DepParser, s::State) = stacktrace(STDOUT, parser, s)

function toconll(io::IO, parser::DepParser, s::State)
    id2word = parser.words.idkey
    id2tag = parser.tags.idkey
    id2label = parser.labels.idkey
    pred = heads(s)
    for i in 1:length(s.tokens)
        t = s.tokens[i]
        items = [i, id2word[t.word], "-", id2tag[t.tag],
                    pred[i], t.head, id2label[t.label]]
        println(io, join(items, "\t"))
    end
    println(io, "")
end
toconll(parser::DepParser, s::State) = toconll(STDOUT, parser, s)

