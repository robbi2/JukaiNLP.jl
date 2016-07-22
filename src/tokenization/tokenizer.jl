export Tokenizer

function model()
    T = Float32
    embed = Embed(T,100,10)
    conv = Conv(T, (10,7), (1,70), paddims=(0,3))
    l = Linear(T,70,4)
    (x::Vector{Int}) -> begin
        x = Var(reshape(x,1,length(x)))
        x = embed(x)
        x = conv(x)
        x = reshape(x, size(x,2), size(x,3))
        x = transpose(x)
        x = relu(x)
        x = l(x)
        x
    end
end

type Tokenizer
    dict::Dict
    nn
end

function Tokenizer()
    path = joinpath(Pkg.dir("JukaiNLP"),"dict/en-char.dict")
    dict = readdict(path)
    Tokenizer(dict, model())
end
