
push!(LOAD_PATH, "..")
using JukaiNLP: DepParser, Perceptron, readconll, train!, decode, evaluate

using DocOpt

doc = """shift-reduce parser

Usage:
    demo.jl --worddict=<worddict> --train=<trainsents> --test=<testsents> [--iter=<iter>]

Options:
    --test test
    --train train
"""

args = docopt(doc)
worddict = args["--worddict"]
trainfile = args[ "--train" ]
testfile = args[ "--test" ]
iter = args["--iter"] == nothing ? 20 : parse(Int, args["--iter"])

model = Perceptron(zeros(1<<26,4))
parser = DepParser(worddict, model)
train!(parser, trainfile, iter=iter)
res = decode(parser, testfile)
evaluate(parser, res)


