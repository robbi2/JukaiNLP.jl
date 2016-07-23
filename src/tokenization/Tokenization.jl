module Tokenization

import ..JukaiNLP
using Compat
using Merlin
export decode, train, tokenize

include("io.jl")
include("tokenizer.jl")
include("decode.jl")
include("train.jl")

end
