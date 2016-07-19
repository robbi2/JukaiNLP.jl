const word2id = Dict()
const tag2id = Dict()
const label2id = Dict()
const id2word = Dict()
const id2tag = Dict()
const id2label = Dict()

function readworddict!(path)
    for line in open(readlines, path)
        word = chomp(line)
        word2id[word] = length(word2id) + 1
    end
end

type Token
    word::Int
    tag::Int
    head::Int
    label::Int
end

rootword = Token(0, 0, 0, 0)

function Token(word::AbstractString, tag, head, label)
    word = replace(lowercase(word), r"\d", "0")
    wordid = get(word2id, word, 1) # words[1] == UNKNOWN
    tagid = get!(tag2id, tag, length(tag2id) + 1)
    headid = parse(Int, head)
    labelid = get!(label2id, label, length(label2id) + 1)
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
    merge!(id2word, Dict([v => k for (k, v) in word2id]))
    merge!(id2tag, Dict([v => k for (k, v) in tag2id]))
    merge!(id2label, Dict([v => k for (k, v) in label2id]))
    doc
end
