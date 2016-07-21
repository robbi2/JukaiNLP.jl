# JukaiNLP: NLP Toolkit based on Deep Learning

[![Build Status](https://travis-ci.org/hshindo/JukaiNLP.jl.svg?branch=master)](https://travis-ci.org/hshindo/JukaiNLP.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/github/hshindo/JukaiNLP.jl?branch=master)](https://ci.appveyor.com/project/hshindo/jukaiNLP-jl/branch/master)

`JukaiNLP` is a natural language processing toolkit in [Julia](http://julialang.org/) based on a deep learning framework: [Merlin](https://github.com/hshindo/Merlin.jl).

## Installation
```julia
julia> Pkg.clone("https://github.com/hshindo/Merlin.jl.git")
julia> Pkg.clone("https://github.com/hshindo/JukaiNLP.jl.git")
julia> Pkg.update()
```

### Dependency Parser
```julia
using JukaiNLP: Perceptron, DepParser, readconll, train, decode, evaluate
model = Perceptron(zeros(1<<26,4))
parser = DepParser("dict/en-word_nyt.dict", model)
trainsents = readconll(parser, "corpus/wsj_02-21.conll")
testsents = readconll(parser, "corpus/wsj_23.conll")
train!(parser, trainsents, iter=20)
# can also pass testsents as 3rd argument
# to see the accuracy on the test data after every iteration
train!(parser, trainsents, testsents, iter=20)
# turn off the progress bar
train!(parser, trainsents, iter=20, progbar=false)
res = decode(parser, testsents)
evaluate(parser, res)
```
