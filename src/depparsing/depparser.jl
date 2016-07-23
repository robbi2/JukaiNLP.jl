export DepParser

abstract ParserType
type Unlabeled <: ParserType end
type Labeled <: ParserType end

type DepParser{T <: ParserType}
    words::IdDict{AbstractString}
    tags::IdDict{AbstractString}
    labels::IdDict{AbstractString}
    parsertype::Type{T}
    model

    function DepParser(words, tags, labels, parsertype)
        new(words, tags, labels, parsertype)
    end
end

function DepParser{T <: ParserType}(path::AbstractString; parsertype::Type{T}=Unlabeled)
    words = IdDict(path)
    tags = IdDict(AbstractString)
    labels = IdDict(AbstractString)
    DepParser{T}(words, tags, labels, parsertype)
end

