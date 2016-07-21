export DepParser

type DepParser
    words::IdDict{AbstractString}
    tags::IdDict{AbstractString}
    labels::IdDict{AbstractString}
    model
end

<<<<<<< HEAD
function DepParser(path::AbstractString, model)
    words = IdDict(path)
    tags = IdDict(AbstractString)
    labels = IdDict(AbstractString)
    DepParser(words, tags, labels, model)
end

=======
using Compat
using ProgressMeter
using TransitionParser

include("utils.jl")
include("token.jl")
include("arcstd.jl")
include("perceptron.jl")
include("training.jl")
include("accuracy.jl")

wordspath = "../../dict/en-word_nyt.dict"
trainpath = "../../corpus/wsj_02-21.conll"
testpath = "../../corpus/wsj_23.conll"

#train()
>>>>>>> 05ecda532b39d9fd369f877bfaf3ab5cba751852
