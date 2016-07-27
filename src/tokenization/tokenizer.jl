type ConvNN
    embed
    conv
    linear
end

function ConvNN()
    T = Float32
    embed = Embed(T,100,10)
    conv = Conv(T, (10,7), (1,70), paddims=(0,3))
    linear = Linear(T,70,4)
    ConvNN(embed, conv, linear)
end

@compat function (m::ConvNN)(x::Vector{Int})
    x = Var(reshape(x,1,length(x)))
    x = m.embed(x)
    x = m.conv(x)
    x = reshape(x, size(x,2), size(x,3))
    x = transpose(x)
    x = relu(x)
    x = m.linear(x)
    x
end

type Tokenizer
    dict::IdDict
    model
    tagset::Tagset
end

@compat function (t::Tokenizer)(chars::Vector{Char})
    unk = t.dict["UNKNOWN"]
    x = map(chars) do c
        get(t.dict, string(c), unk)
    end
    y = t.model(x).data
    tags = argmax(y, 1)
    decode(t.tagset, tags)
end
@compat (t::Tokenizer)(str::String) = t(Vector{Char}(str))
