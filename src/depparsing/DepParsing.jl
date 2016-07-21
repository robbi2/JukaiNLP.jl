module DepParsing

using ..JukaiNLP
using Compat
using ProgressMeter
using TransitionParser: beamsearch, max_violation!, to_seq

include("../iddict.jl")
include("depparser.jl")
include("utils.jl")
include("token.jl")
include("arcstd.jl")
include("perceptron.jl")
include("training.jl")
include("accuracy.jl")

export State,
       DepParser,
       Perceptron,
       readconll,
       train!,
       decode,
       evaluate

# model = JukaiNLP.Perceptron(zeros(1<<26,4))
# parser = JukaiNLP.DepParser(dictpath, model)
# trainsents = JukaiNLP.readconll(parser, trainpath)
# testsents = JukaiNLP.readconll(parser, testpath)
#
# JukaiNLP.train(parser, trainsents, testsents, iter=20)

end
