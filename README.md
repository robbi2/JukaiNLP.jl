# JukaiNLP: NLP Toolkit based on Deep Learning

[![Build Status](https://travis-ci.org/hshindo/JukaiNLP.jl.svg?branch=master)](https://travis-ci.org/hshindo/JukaiNLP.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/github/hshindo/JukaiNLP.jl?branch=master)](https://ci.appveyor.com/project/hshindo/jukaiNLP-jl/branch/master)

`JukaiNLP` is a natural language processing toolkit in [Julia](http://julialang.org/) based on a deep learning framework: [Merlin](https://github.com/hshindo/Merlin.jl).

## Installation
```julia
julia> Pkg.clone("https://github.com/hshindo/Merlin.jl.git")
julia> Pkg.clone("https://github.com/hshindo/TransitionParser.jl.git")
julia> Pkg.clone("https://github.com/hshindo/JukaiNLP.jl.git")
julia> Pkg.update()
```

## Tokenization
```julia
using JukaiNLP
using JLD

# training
trainpath = joinpath(Pkg.dir("JukaiNLP"), "corpus/webtreebank.conll")
t = Tokenizer()
train(t, trainpath)
modelpath = "C:/Users/hshindo/Desktop/tokenizer_50.jld"
save(modelpath, "tokenizer", t)

# testing
t = load(modelpath, "tokenizer")
str = "Pierre Vinken, 61 years old, will join the board. I have a pen. "
doc = decode(t, str)
map(r -> str[r], doc[1])
```

## Dependency Parsing
```julia
using JukaiNLP: Perceptron, DepParser, Unlabeled, Labeled
using JukaiNLP: readconll, train!, decode, evaluate
# parser for unlabeled dependency tree
parser = DepParser("dict/en-word_nyt.dict", parsertype=Unlabeled)
# parser for labeled dependency tree
parser = DepParser("dict/en-word_nyt.dict", parsertype=Labeled)
sents = readconll(parser, "corpus/mini-training-set.conll")
initmodel!(parser, Perceptron)
n = div(length(sents), 10) * 8
trainsents, testsents = sents[1:n], sents[n+1:end]
train!(parser, trainsents, iter=20)
# can also pass testsents as 3rd argument
# to see the accuracy on the test data after every iteration
train!(parser, trainsents, testsents, iter=20)
# turn off the progress bar
train!(parser, trainsents, iter=20, progbar=false)
res = decode(parser, testsents)
evaluate(parser, res)
```
