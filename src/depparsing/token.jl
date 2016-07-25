
type Token
    word::Int
    tag::Int
    head::Int
    label::Int
end

rootword = Token(0, 0, 0, 0)

function readconll(parser::DepParser, path::AbstractString)
    doc = Vector{Token}[]
    push!(doc, Token[])
    for line in open(readlines, path)
        line = chomp(line)
        if isempty(line)
            push!(doc, Token[])
        else
            items = split(line)
            word, tag, head, label = items[2], items[4], items[7], items[8]
            word = replace(lowercase(word), r"\d", "0")
            wordid = get(parser.words, word, 1) # words[1] == UNKNOWN
            tagid = push!(parser.tags, tag)
            headid = parse(Int, head)
            labelid = push!(parser.labels, label)
            t = Token(wordid, tagid, headid, labelid)
            push!(doc[end], t)
        end
    end
    doc
end
