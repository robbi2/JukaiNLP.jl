export Tokenizer

type Tokenizer
    dict::Dict
    nn
end

function Tokenizer(dictfile)
    dict = readdict(joinpath(dictpath,dictfile))
    #nn = @graph begin
    #  T = Float32
    #  x = Var(:x)
    #  x = Lookup(T,100,10)(x)
    #  x = Window2D(10,7,1,1,0,3)(x)
    #  x = Linear(T,70,70)(x)
    #  x = relu(x)
    #  x = Linear(T,70,4)(x)
    #  x
    #end
    nn = nothing
    Tokenizer(dict, nn)
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

function readconll(path)
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
    data_x = map(x -> Var(reshape(x, 1, length(x))), data_x)
    data_y = map(Var, data_y)
    data_x, data_y
end

function readdict(path)
    dict = Dict()
    for line in open(readlines, path)
        get!(dict, chomp(line), length(dict)+1)
    end
    dict
end

include("decode.jl")
include("train.jl")
