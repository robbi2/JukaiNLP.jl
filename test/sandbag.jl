workspace()
using Merlin
using JukaiNLP
using JukaiNLP: Tokenization, Tagging
using JLD

# setup tagger
dirpath = Pkg.dir("JukaiNLP")
t = Tagger()

trainpath = "C:/Users/shindo/Dropbox/tagging/wsj_00-18.conll"
traindata = readconll(trainpath, [2,5])[1:10000]
testpath = "C:/Users/shindo/Dropbox/tagging/wsj_22-24.conll"
testdata = readconll(testpath, [2,5])
Tagging.train(t, 30, traindata, testdata)

# setup tokenizer
dirpath = Pkg.dir("JukaiNLP")
t = Tokenizer()

# training
trainpath = "$(dirpath)/corpus/mini-training-set.conll"
data = readconll(trainpath, [2,11])
train(t, 100, data)
modelpath = "C:/Users/shindo/Desktop/tokenizer_20.jld"
JLD.save(modelpath, "tokenizer", t.model)
t.model.code

# testing
t = JLD.load(modelpath, "tokenizer")
str = "Pierre Vinken, 61 years old, will join the board.\nI have a pen.\n"
result = t(str)
join(map(r -> str[r], result), " ")
