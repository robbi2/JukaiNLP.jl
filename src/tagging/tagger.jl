type Model
end

function Model()
    
end

type Tagger
    word_dict::IdDict
    char_dict::IdDict
    tag_dict::IdDict
    model
end

function Tagger()
    Tagger(IdDict(), IdDict(), IdDict(), nothing)
end

@compat function(t::Tagger){T<:String}(words::Vector{T})
    unkword = 1
    unkchar = 1
    x = map(words) do w
        chars = Vector{Char}(w)
        map(c -> get(t.char_dict,string(c),unkchar), chars)
        get(t.dict, string(c), unk)
    end
    y = t.model(x).data
    tags = argmax(y, 1)
    decode(t.tagset, tags)
end
