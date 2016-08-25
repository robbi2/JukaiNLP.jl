workspace()
using Merlin
using JukaiNLP
using JukaiNLP: Tokenization, Tagging
using HDF5

filename = joinpath(Pkg.dir("JukaiNLP"), ".corpus/nyt100.h5")
words = h5read(filename, "str")

path = joinpath(Pkg.dir("JukaiNLP"), ".corpus/nyt100.h5")
a = h5read(path, "Merlin")

path = "C:/Users/hshindo/Desktop/20070723111604AAzUvhb_ans.conll"
rawtext(path) |> println
