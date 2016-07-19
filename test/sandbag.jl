workspace()
using JukaiNLP

using Merlin

pwd()
trainfile = "corpus/wsj_02-21.conll"
testfile = "corpus/wsj_23.conll"

t = Tokenizer("en-char.dict")
p = DepParser()
