
ccall(:jl_exit_on_sigint, Void, (Cint,), 0)

push!(LOAD_PATH, "..")
using JukaiNLP: DepParser, Perceptron, Unlabeled, Labeled, FeedForward
using JukaiNLP: readconll, train!, decode, evaluate, toconll, initmodel!
using JukaiNLP.DepParsing: Token
# using JLD
using DocOpt

doc = """shift-reduce parser

Usage:
    demo.jl train (--labeled | --unlabeled) --nn --worddict <worddict>
    <train_path> <model_path> [<test_path>] [--iter=<iter>] [--embedfile <embed_file>] [--batchsize=<batch>] [--evaliter=<eval>]
    demo.jl train (--labeled | --unlabeled) --perceptron --worddict <worddict>
    <train_path> <model_path> [<test_path>] [--iter=<iter>]

    demo.jl test <test_path> <model_path>
    demo.jl (<sent> | -) <model_path>

Options:
    <train_path>    path to CoNLL format file to use for training
    <test_path>     path to CoNLL format file to use for evaluation
    <model_path>    path to output resulting parser model

"""
    # --iter          number of training iteration
    # --embedfile     path to pretrained embedding file (used in --nn)
    # --batchsize     batch size (used in --nn)
    # --evaliter      run evaluation on test data every after this number of iteration

args = docopt(doc)

# function saveparser{T}(parser::DepParser{T}, path::AbstractString)
#     println("\nsaving model to $(path)...")
#     open(io -> serialize(io, parser), path, "w")
#     # save(args["<model_path>"], "parser", parser)
#     println("done")
# end

worddict = args["<worddict>"]
parsertype = args["--labeled"] ? Labeled :
             args["--unlabeled"] ? Unlabeled :
             nothing
iter = args["--iter"] != nothing ? parse(Int, args["--iter"]) :
       args["--perceptron"] ? 20 :
       args["--nn"] ? 20000 : nothing
embedfile = args["--embedfile"] ? args["<embed_file>"] : ""
trainfile = args["<train_path>"]
testfile = args["<test_path>"]
modelpath = args["<model_path>"]
batchsize = args["--batchsize"] != nothing ? parse(Int, args["--batchsize"]) : 10000
evaliter = args["--evaliter"] != nothing ? parse(Int, args["--evaliter"]) : 100


if args["train"]
    parser = DepParser(parsertype, worddict)
    trainsents = readconll(parser, trainfile)
    testsents = testfile == nothing ? Vector{Token}[] :
                readconll(parser, testfile, train=false)
    if args["--nn"]
        train!(FeedForward, parser, trainsents, testsents, embed=embedfile,
            iter=iter, batchsize=batchsize, evaliter=evaliter, outfile=modelpath)
    elseif args["--perceptron"]
        train!(Perceptron, parser, trainsents, testsents,
            iter=iter, outfile=modelpath)
    end

elseif args["test"]
    # parser = load(args["<model_path>"], "parser")
    parser = open(deserialize, modelpath)
    res = parser(testfile)
    for s in res
        toconll(s)
    end
    evaluate(parser, res)

elseif args["<sent>"] == "-"
    throw("yet to be supported")

elseif args["<sent>"] != nothing
    throw("yet to be supported")
end


