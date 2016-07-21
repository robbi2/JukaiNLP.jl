workspace()
using JukaiNLP
using JLD
using Merlin

trainpath = joinpath(Pkg.dir("JukaiNLP"), "corpus/webtreebank.conll")
t = Tokenizer()
train(t, trainpath)

modelpath = "C:/Users/hshindo/Desktop/tokenizer_50.jld"
save(modelpath, "tokenizer", t)

t = load(modelpath, "tokenizer")
str = "Pierre Vinken, 61 years old, will join the board. I have a pen. "
doc = decode(t, str)
map(r -> str[r], doc[1])

JukaiNLP.Tokenization.tokenize(chars, tags)
