module JukaiNLP

using Compat
# using Merlin
using ProgressMeter

export decode, train

include("iddict.jl")
#include("accuracy.jl")
#include("beamsearch.jl")
# include("tokenization/Tokenization.jl")
include("depparsing/DepParsing.jl")

# using .Tokenization
# export Tokenizer
using .DepParsing
export DepParser

end
