type Tagger
    dict::IdDict
    model
end

function Tagger()
    #word_dict = load(IdDict{ASCIIString}, "en-word_nyt.dict")
    char_dict = load(IdDict{ASCIIString}, joinpath(Pkg.dir("JukaiNLP"),"dict/en-char.dict"))
    Tagger(char_dict, nothing)
end

@compat function(t::Tagger)(tokens::Vector)

end
