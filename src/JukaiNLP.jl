module JukaiNLP

using Compat
using Merlin
using ProgressMeter

const global dictpath = joinpath(Pkg.dir("JukaiNLP"), "dict")

export decode, train

include("tokenization/Tokenization.jl")
include("depparsing/DepParsing.jl")

using .Tokenization
export Tokenizer
using .DepParsing
export DepParser

end
