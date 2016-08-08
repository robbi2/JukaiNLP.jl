workspace()
using JukaiNLP
using JukaiNLP: Tokenization, Tagging
using JLD

# setup tokenizer
dirpath = Pkg.dir("JukaiNLP")
t = Tokenizer()

# training
trainpath = "$(dirpath)/corpus/mini-training-set.conll"
data = Tokenization.readtsv(trainpath) do items
    items[2], items[11]
end
train(t, 100, data)
modelpath = "C:/Users/hshindo/Desktop/tokenizer_20.jld"
JLD.save(modelpath, "tokenizer", t)

# testing
t = JLD.load(modelpath, "tokenizer")
str = "Pierre Vinken, 61 years old, will join the board.\nI have a pen.\n"
t.model
result = t(str)
join(map(r -> str[r], result), " ")
