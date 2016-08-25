workspace()
using JukaiNLP
using JukaiNLP.Tagging

path = joinpath(Pkg.dir("JukaiNLP"), ".corpus")
tagger = Tagger("$(path)/nyt100.h5")

traindata = readconll("$(path)/wsj_00-18.conll", [2,5])
testdata = readconll("$(path)/wsj_22-24.conll", [2,5])

train(tagger, 5, traindata, testdata)
