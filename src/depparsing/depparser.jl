export DepParser

type DepParser
    words::IdDict{AbstractString}
    tags::IdDict{AbstractString}
    labels::IdDict{AbstractString}
    model
end

function DepParser(path::AbstractString, model)
    words = IdDict(path)
    tags = IdDict(AbstractString)
    labels = IdDict(AbstractString)
    DepParser(words, tags, labels, model)
end
