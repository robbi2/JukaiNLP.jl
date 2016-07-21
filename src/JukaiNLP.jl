module JukaiNLP

using Compat
<<<<<<< HEAD
# using Merlin
=======
>>>>>>> 05ecda532b39d9fd369f877bfaf3ab5cba751852
using ProgressMeter

export decode, train

<<<<<<< HEAD
include("iddict.jl")
include("accuracy.jl")
include("beamsearch.jl")
=======
>>>>>>> 05ecda532b39d9fd369f877bfaf3ab5cba751852
include("tokenization/Tokenization.jl")
include("depparsing/DepParsing.jl")

# using .Tokenization
# export Tokenizer
using .DepParsing
export DepParser

end
