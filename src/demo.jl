
using JukaiNLP: DepParser, Perceptron, readconll, train!, decode, evaluate

using DocOpt

doc = """shift-reduce parser

Usage:
    demo.jl --worddict=<worddict> --train=<trainsents> --test=<testsents> [--iter=<iter>]

Options:
    --test test
    --train train
"""
# something wrong with DocOpt?
# args = docopt(doc)

args = Dict("<worddict>" => "../dict/en-word_nyt.dict",
            "<trainsents>" => "../corpus/wsj_02-21.conll",
            "<testsents>" => "../corpus/wsj_23.conll",
            "<iter>" => "20")

model = Perceptron(zeros(1<<26,4))
parser = DepParser(args["<worddict>"], model)
trainsents = readconll(parser, args["<trainsents>"])
testsents = readconll(parser, args["<testsents>"])
train!(parser, trainsents, iter=parse(Int, args["<iter>"]))

res = decode(parser, testsents)
evaluate(parser, res)


