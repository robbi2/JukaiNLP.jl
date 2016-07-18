module JukaiNLP

using Compat
using Merlin
using ProgressMeter

const global dictpath = joinpath(Pkg.dir("JukaiNLP"), "dict")

export decode, train
export tokenize

include("accuracy.jl")
include("beamsearch.jl")

include("tokenizer/tokenizer.jl")
#include("depparsing/tokenizer.jl")

#module DepParsing
#    include("token.jl")
#    include("accuracy.jl")
#    include("arcstd.jl")
#    include("training.jl")
#end

end
