workspace()
using JukaiNLP
using JLD

dict = JukaiNLP.IdDict{AbstractString}()
id1 = push!(dict, "abc")
id2 = push!(dict, "def")
id3 = push!(dict, "abc")


path = joinpath(Pkg.dir("JukaiNLP"),"corpus/sample_tokenization.conll")
doc = JukaiNLP.Tokenization.readfile(path)
doc[1]

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
