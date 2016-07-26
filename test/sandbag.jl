workspace()
using JukaiNLP
using JukaiNLP.Tokenization
using JLD

# setup tokenizer
dirpath = Pkg.dir("JukaiNLP")
dict = JukaiNLP.load(IdDict{String}, "$(dirpath)/dict/en-char.dict")
model = Tokenization.ConvNN()
t = Tokenizer(dict, model, Tokenization.IOE())

# training
tags = train(t, 100, "$(dirpath)/corpus/mini-training-set.conll")
modelpath = "C:/Users/hshindo/Desktop/tokenizer_20.jld"
JLD.save(modelpath, "tokenizer.model", t.model)

# testing
t.model = JLD.load(modelpath, "tokenizer.model")
str = "Pierre Vinken, 61 years old, will join the board. I have a pen. "
result = t(str)
