type Tokenizer
    dict::IdDict
    tagset::Tagset
    model
end

function Tokenizer()
    dict = IdDict(["UNKNOWN", " ", "\n"])
    Tokenizer(dict, IOE(), Model())
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
