type Tokenizer
    dict::IdDict
    tagset::Tagset
    model
end

function Tokenizer()
    dict = IdDict(map(UTF8String, ["UNKNOWN", " ", "\n"]))
    g = begin
        T = Float32
        local embed = Embedding(T, 100, 10)
        local conv = Conv(T, (10,7), (1,70), paddims=(0,3))
        local linear = Linear(T, 70, 4)
        @graph begin
            x = Var(reshape(:chars,1,length(:chars)))
            x = embed(x)
            x = 
            x = relu(x)
            x = linear(x)
            x
        end
    end
    model = compile(g, :chars)
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
