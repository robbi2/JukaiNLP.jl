workspace()
using JukaiNLP
using JLD

# training
trainpath = joinpath(Pkg.dir("JukaiNLP"), "corpus/webtreebank.conll")
t = Tokenizer()
train(t, trainpath)
modelpath = "C:/Users/shindo/Desktop/tokenizer_20.jld"
save(modelpath, "tokenizer", t)

# testing
t = load(modelpath, "tokenizer")
str = "Pierre Vinken, 61 years old, will join the board. I have a pen. "
doc = decode(t, str)
map(r -> str[r], doc[2])
