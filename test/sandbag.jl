workspace()
using JukaiNLP
using JukaiNLP: Tokenization, Tagging
using JLD

# setup tokenizer
dirpath = Pkg.dir("JukaiNLP")
t = Tokenizer()

# training
tags = train(t, 100, "$(dirpath)/corpus/mini-training-set.conll")
modelpath = "C:/Users/shindo/Desktop/tokenizer_20.jld"
JLD.save(modelpath, "tokenizer", t)

# testing
t = JLD.load(modelpath, "tokenizer")
str = "Pierre Vinken, 61 years old, will join the board.\nI have a pen.\n"
result = t(str)
join(map(r -> str[r], result), " ")
