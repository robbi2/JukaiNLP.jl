const words = Dict()
const tags = Dict()
const labels = Dict()

type Token
    word::Int
    tag::Int
    head::Int
    label::Int
end

function Token(word::AbstractString, tag, head, label)
    wordid = get!(words, word, length(words))
    tagid = get!(tags, tag, length(tags))
    headid = parse(Int, head)
    labelid = get!(labels, label, length(labels))
    Token(wordid, tagid, headid, labelid)
end

function readconll(path)
    doc = Vector{Token}[]
    push!(doc, Token[])
    for line in open(readlines, path)
        line = chomp(line)
        if isempty(line)
            push!(doc, Token[])
        else
            items = split(line)
            word = items[2]
            tag = items[4]
            head = items[7]
            label = items[8]
            t = Token(word, tag, head, label)
            push!(doc[end], t)
        end
    end
    doc
end
