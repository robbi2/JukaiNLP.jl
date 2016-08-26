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
    labeler

    function DepParser(words, tags, labels, parsertype)
        new(words, tags, labels, parsertype)
    end
end

function DepParser{T <: ParserType}(parsertype::Type{T}, path::AbstractString)
    words = IdDict(AbstractString, path)
    tags = IdDict{AbstractString}()
    labels = IdDict{AbstractString}()
    push!(tags, "NONE")
    # push!(labels, "NONE")
    DepParser{T}(words, tags, labels, parsertype)
end

@compat function (parser::DepParser){T}(sents::Vector{Vector{T}})
    model_t = typeof(parser.model)
    decode(model_t, parser, sents)
end

@compat function (parser::DepParser)(filepath::AbstractString)
    sents = readconll(parser, filepath, train=false)
    model_t = typeof(parser.model)
    decode(model_t, parser, sents)
end
