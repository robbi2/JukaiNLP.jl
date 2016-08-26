workspace()
using JukaiNLP
using JukaiNLP.Tagging
using HDF5

#BLAS.set_num_threads(2)
path = joinpath(Pkg.dir("JukaiNLP"), ".corpus")
w = h5read("$(path)/nyt100.h5", "vec")
model = Tagging.POSModel(w)
tagger = Tagger("$(path)/nyt100.h5", model)

traindata = readconll("$(path)/wsj_00-18.conll", [2,5])
testdata = readconll("$(path)/wsj_22-24.conll", [2,5])

train(tagger, 5, traindata, testdata)
