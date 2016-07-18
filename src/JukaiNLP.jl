module JukaiNLP

using Compat
using ProgressMeter

include("token.jl")
include("beamsearch.jl")
include("eval.jl")
include("arcstd.jl")
include("training.jl")

#include("utils.jl")
#include("tokens.jl")
# include("arceager.jl")
#include("arcstd.jl")
#include("perceptron.jl")

#global trainfile = "corpus/wsj_02-21.conll"
#global testfile = "corpus/wsj_23.conll"

#@ConllFormat num word :- tag :- :- head label :- :-

end
