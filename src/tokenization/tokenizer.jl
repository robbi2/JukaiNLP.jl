export Tokenizer

type Model
    embed
    conv
    l1
    l2
end

function Model()
    T = Float32
    embed =Embed(T,100,10)
    conv = Conv(T, (10,7), (1,70), paddims=(0,3))
    Model(embed, conv, Linear(T,70,70), Linear(T,70,4))
end

@compat function (m::Model)(x::Vector{Int})
    x = Var(reshape(x,1,length(x)))
    x = m.embed(x)
    x = m.conv(x)
    x = reshape(x, size(x,2), size(x,3))
    x = transpose(x)
    x |> m.l1 |> relu |> m.l2
end

type Tokenizer
    dict::Dict
    nn::Model
end

function Tokenizer()
    path = joinpath(Pkg.dir("JukaiNLP"),"dict/en-char.dict")
    dict = readdict(path)
    Tokenizer(dict, Model())
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

function readdict(path)
    dict = Dict()
    for line in open(readlines, path)
        get!(dict, chomp(line), length(dict)+1)
    end
    dict
end
