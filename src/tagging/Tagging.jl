module Tagging

importall ..JukaiNLP
using Compat
import Compat.String
using Merlin

export train, Tagger

include("io.jl")
include("tagger.jl")

end
