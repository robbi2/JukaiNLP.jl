module Tokenization

importall ..JukaiNLP
using Compat
import Compat.String
using Merlin

export train, Tokenizer

include("tagset.jl")
include("tokenizer.jl")
include("train.jl")

end
