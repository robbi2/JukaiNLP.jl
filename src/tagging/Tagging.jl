module Tagging

importall ..JukaiNLP
using Compat
using Merlin
import Compat.String

export train, Tagger

include("token.jl")
include("wordcharcnn.jl")
include("model.jl")
include("tagger.jl")
include("train.jl")

end
