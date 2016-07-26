function readfile(path::String, dict::IdDict)
    unk, space, lf = dict["UNKNOWN"], dict[" "], dict["LF"]
    chars = Int[]
    ranges = UnitRange{Int}[]
    lines = open(readlines, path)
    pos = 1
    for line in lines
        line = chomp(line)
        if isempty(line)
            continue
        end
        items = split(line, '\t')

        for c in items[11]
            c == '_' && continue
            if c == 'S'
                push!(chars, space)
            elseif c == 'N'
                push!(chars, lf)
            end
            pos += 1
        end

        form = items[2]
        for c in form
            push!(chars, get(dict,string(c),unk))
        end
        push!(ranges, pos:pos+length(form)-1)
        pos += length(form)
    end
    chars, ranges
end

function readfile2(path::String, dict::IdDict)
    unk, space, lf = dict["UNKNOWN"], dict[" "], dict["LF"]
    chars, tags = Int[], Int[]
    lines = open(readlines, path)
    for i = 1:length(lines)
        line = chomp(lines[i])
        if isempty(line)
            tags[end] = Tagset.ES
            continue
        end
        items = split(line, '\t')

        for c in items[11]
            if c == 'S'
                cc = space
            elseif c == 'N'
                cc = lf
            else
                continue
            end
            push!(chars, cc)
            push!(tags, Tagset.O)
        end

        form = items[2]
        for c in form
            push!(chars, get(dict,string(c),unk))
            push!(tags, Tagset.I)
        end
        tags[end] = Tagset.ET
    end
    chars, tags
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
