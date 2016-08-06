
type Token
    word::Int
    tag::Int
    head::Int
    label::Int
end

roottoken = Token(2, 1, 0, 1) # use PADDING

function readconll(parser::DepParser, path::AbstractString; train=true)
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
            tagid = train ? push!(parser.tags, tag) : get(parser.tags, tag, 1)
            headid = parse(Int, head)
            labelid = train ? push!(parser.labels, label) : get(parser.labels, label, 1)
            t = Token(wordid, tagid, headid, labelid)
            push!(doc[end], t)
        end
    end
    doc
end
