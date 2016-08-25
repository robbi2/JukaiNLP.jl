type Tagger
    word_dict::IdDict
    char_dict::IdDict
    tag_dict::IdDict
    model
end

function Tagger(filename)
    words = h5read(filename, "str")
    word_dict = IdDict(words)
    char_dict = IdDict(map(UTF8String, ["UNKNOWN","="]))
    Tagger(word_dict, char_dict, IdDict(), POSModel(""))
end

function (t::Tagger)(words::Vector)
    unkword = t.word_dict["UNKNOWN"]
    tokens::Vector{Token} = map(words) do word
        word0 = replace(word, r"[0-9]", '0') |> lowercase
        wordid = get(t.word_dict, word0, unkword)
        chars = Vector{Char}(word)
        charids = map(c -> t.char_dict[string(c)], chars) # TODO: handle unknown char
        Token(wordid, charids)
    end
    y = t.model(tokens).data
    tags = argmax(y, 1)
    tags
end
