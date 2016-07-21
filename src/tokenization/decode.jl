function decode(t::Tokenizer, x::Vector{Int})
    y = t.nn(x)
    argmax(y.data, 1)
end

function decode(t::Tokenizer, chars::Vector{Char})
    unk = t.dict["UNKNOWN"]
    x = map(chars) do c
        get(t.dict, string(c), unk)
    end
    tags = decode(t,x)
    tags[end] = 4

    bpos = 0 # begining position
    doc = []
    tokens = []
    for i = 1:length(chars)
        t = tags[i]
        if t == 1
            bpos == 0 && (bpos = i)
        elseif t == 3
            bpos == 0 && (bpos = i)
            push!(tokens, bpos:i)
            bpos = 0
        elseif t == 4
            bpos == 0 && (bpos = i)
            push!(tokens, bpos:i)
            push!(doc, tokens)
            tokens = []
            bpos = 0
        end
    end
    doc
end
decode(t::Tokenizer, str::AbstractString) = decode(t, Vector{Char}(str))
