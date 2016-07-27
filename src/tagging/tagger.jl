type Tagger
    word_dict::IdDict
    char_dict::IdDict
    model
end

@compat function(t::Tagger){T<:String}(words::Vector{T})
    unk = t.word_dict["UNKNOWN"]
    x = map(words) do w
        chars =
        get(t.dict, string(c), unk)
    end
    y = t.model(x).data
    tags = argmax(y, 1)
    decode(t.tagset, tags)
end
