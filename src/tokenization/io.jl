function readfile(path, dict::IdDict)
    unk, space, lf = dict["UNKNOWN"], dict[" "], dict["\n"]
    chars = Int[]
    ranges = UnitRange{Int}[]
    lines = open(readlines, path)
    pos = 1
    for line in lines
        line = chomp(line)
        if isempty(line) # end of sentence
            continue
        end
        items = split(line, '\t')

        for c in items[end]
            c == '_' && continue
            if c == 'S' # space
                push!(chars, space)
            elseif c == 'N' # newline
                push!(chars, lf)
            end
            pos += 1
        end

        form = items[24]
        for c in form
            push!(chars, push!(dict,string(c)))
        end
        push!(ranges, pos:pos+length(form)-1)
        pos += length(form)
    end
    chars, ranges
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
