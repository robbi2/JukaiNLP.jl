type Tokenizer
    dict::IdDict
    tagset::Tagset
    model
end

function Tokenizer(tagset)
    dict = IdDict(["UNKNOWN", " ", "LF"])
    model = begin
        T = Float32
        embed = Embed(T,100,10)
        conv = Conv(T,(10,7),(1,70),paddims=(0,3))
        linear = Linear(T,70,4)

        (x::Vector{Int}) -> begin
            x = Var(reshape(x,1,length(x)))
            x = x |> embed |> conv
            x = reshape(x, size(x,2), size(x,3))
            x |> transpose |> relu |> linear
        end
    end
    Tokenizer(dict, tagset, model)
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
