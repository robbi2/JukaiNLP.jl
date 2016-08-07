type Tokenizer
    dict::IdDict
    tagset::Tagset
    model
end

function Tokenizer()
    dict = IdDict(map(UTF8String, ["UNKNOWN", " ", "\n"]))
    T = Float32
    model = Sequence(
        x -> Var(reshape(x,1,length(x))),
        Embedding(T,100,10),
        Conv(T,(10,7),(1,70),paddims=(0,3)),
        x -> reshape(x, size(x,2), size(x,3)),
        transpose,
        relu,
        Linear(T,70,4)
    )
    Tokenizer(dict, IOE(), model)
end

@compat function (t::Tokenizer)(chars::Vector{Char})
    unk = t.dict["UNKNOWN"]
    x = map(chars) do c
        get(t.dict, string(c), unk)
    end
    y = t.model(x).data
    tags = argmax(y,1)
    decode(t.tagset, tags)
end
@compat (t::Tokenizer)(str::String) = t(Vector{Char}(str))
