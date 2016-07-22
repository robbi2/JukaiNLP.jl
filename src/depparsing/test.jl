
push!(LOAD_PATH, "src")
using JukaiNLP: Perceptron, DepParser, readconll
using JukaiNLP.DepParsing: expandgold, State, isfinal
using TransitionParser: beamsearch

parser = DepParser("dict/en-word_nyt.dict", Perceptron(zeros(100, 3)))
sents = readconll(parser, "corpus/mini-training-set.conll")
state = beamsearch(1, State(sents[1]), expandgold)

@test isfinal(state)
