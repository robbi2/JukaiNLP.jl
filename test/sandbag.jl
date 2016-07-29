workspace()
using JukaiNLP
using JukaiNLP: Tokenization, Tagging
using JLD

# setup tagger
dirpath = Pkg.dir("JukaiNLP")
word_dict = JukaiNLP.load(IdDict{String}, "$(dirpath)/dict/en-word_nyt.dict")
char_dict = JukaiNLP.load(IdDict{String}, "$(dirpath)/dict/en-char.dict")

# setup tokenizer
dirpath = Pkg.dir("JukaiNLP")
#dict = JukaiNLP.load(IdDict, "$(dirpath)/dict/en-char.dict")
#model = Tokenization.ConvNN()
t = Tokenizer(Tokenization.IOE())

# training
tags = @time train(t, 100, "$(dirpath)/corpus/mini-training-set.conll")
modelpath = "C:/Users/hshindo/Desktop/tokenizer_20.jld"
JLD.save(modelpath, "tokenizer", t)

# testing
t = JLD.load(modelpath, "tokenizer")
str = "Pierre Vinken, 61 years old, will join the board. I have a pen. "
result = t(str)
map(r -> str[r], result) |> println
