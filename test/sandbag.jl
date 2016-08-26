workspace()
using Merlin
using JukaiNLP
using JukaiNLP: Tokenization, Tagging
using HDF5

path = joinpath(Pkg.dir("JukaiNLP"), ".corpus/nyt100.lst")
e = Embedding(path,Float32)
a = h5read(path, "Merlin")

path = "C:/Users/hshindo/Desktop/20070723111604AAzUvhb_ans.conll"
rawtext(path) |> println

x = rand(Float32,100000,300)
