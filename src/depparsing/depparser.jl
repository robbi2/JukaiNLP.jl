export DepParser

type DepParser
end

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
