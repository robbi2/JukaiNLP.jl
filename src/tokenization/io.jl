function readfile(path)
    data = readtsv(path)
    for lines in data
        chars = Int[]
        for line in lines
            items = split(line, '\t')
            ids = map(c -> get!(dict, c, length(dict)+1), items[2])
            append!(chars, ids)
            

            append!(chars, items[2])
            if items[2] == " "
            end
        end
    end

    doc = split(data, '\n', keep=false)
    doc
end

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

#=
function readconll(t::Tokenizer, path)
    unk = t.dict["UNKNOWN"]
    data_x, data_y = Vector{Int}[], Vector{Int}[]
    doc = readtsv(path)
    for sent in doc
        push!(data_x, Int[])
        push!(data_y, Int[])
        for items in sent
            char = items[2]
            char == "LF" && (char = "\n")
            charid = get(t.dict, char, unk)
            tagid = parse(Int, items[3])
            push!(data_x[end], charid)
            push!(data_y[end], tagid)
        end
    end
    data_y = map(Var, data_y)
    data_x, data_y
end
=#
function readdict(path)
    dict = Dict()
    for line in open(readlines, path)
        get!(dict, chomp(line), length(dict)+1)
    end
    dict
end
