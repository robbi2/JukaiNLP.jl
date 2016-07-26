type Token
    id::Int
    word::Int
    chars::Vector{Int}
    tag::Int
end

function readfile(path, word_dict::IdDict, char_dict::IdDict)
    doc = Vector{Token}[]
    tokens = Token[]
    unkword = word_dict["UNKNOWN"]
    for line in open(readlines, path)
        line = chomp(line)
        if isempty(line)
            isempty(tokens) || push!(doc, tokens)
            tokens = Token[]
        else
            items = split(line, '\t')
            id = parse(Int, items[1])
            form = items[2]
            form0 = replace(form, r"[0-9]", '0') |> lowercase
            formid = get(word_dict, form0, unkword)
            cat = get(cat_dict, items[5], unkcat)
            head = parse(Int, items[7])
            push!(tokens, Token(id, formid, cat, head))
        end
    end
    isempty(tokens) || push!(doc, tokens)
    doc
end

#=
function readtsv(path)
doc = Vector{Vector{AbstractString}}[]
sent = Vector{AbstractString}[]
lines = open(readlines, path)
for line in lines
line = chomp(line)
if length(line) == 0
length(sent) > 0 && push!(doc, sent)
sent = Vector{AbstractString}[]
else
items = split(line, '\t')
push!(sent, items)
end
end
length(sent) > 0 && push!(doc, sent)
doc
end
=#
