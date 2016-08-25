using JukaiNLP
using JukaiNLP.Tokenization

# setup tokenizer
dirpath = Pkg.dir("JukaiNLP")
t = Tokenizer()

# training
trainpath = "$(dirpath)/corpus/mini-training-set.conll"
data = readconll(trainpath, [2,11])
Tokenization.train(t, 100, data)
modelpath = "C:/Users/shindo/Desktop/tokenizer_20.jld"
JLD.save(modelpath, "tokenizer", t.model)
t.model.code

# testing
t = JLD.load(modelpath, "tokenizer")
str = "Pierre Vinken, 61 years old, will join the board.\nI have a pen.\n"
result = t(str)
join(map(r -> str[r], result), " ")
