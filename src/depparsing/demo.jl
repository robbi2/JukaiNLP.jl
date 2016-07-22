
push!(LOAD_PATH, "..")
using JukaiNLP: DepParser, Perceptron, readconll, train!, decode, evaluate, toconll
using JLD
using DocOpt

doc = """shift-reduce parser

Usage:
    demo.jl train [--worddict=<worddict>] <train_path> <model_path> [--iter=<iter>]
    demo.jl test <test_path> <model_path>
    demo.jl (<sent> | -) <model_path>

Options:
    <train_path>    path to file with sentences in CoNLL format to use for training
    <test_path>     path to file with sentences in CoNLL format to use for evaluation
    <model_path>    path to output resulting parser model in JLD
    
"""

args = docopt(doc)


if args["train"]
    worddict = args["--worddict"]
    worddict == nothing && throw("worddict must be specified for now")
    parser = DepParser(worddict, Perceptron(zeros(1<<13,4)))
    iter = args["--iter"] == nothing ? 20 : parse(Int, args["--iter"])
    trainfile = args["<train_path>"]
    train!(parser, trainfile, iter=iter)
    save(args["<model_path>"], "parser", parser)

elseif args["test"]
    parser = load(args["<model_path>"], "parser")
    testfile = args["<test_path>"]
    res = decode(parser, testfile)
    for s in res
        toconll(parser, s)
    end
    evaluate(parser, res)

elseif args["<sent>"] == "-"
    throw("yet to be supported")

elseif args["<sent>"] != nothing
    throw("yet to be supported")
end


