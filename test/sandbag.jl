workspace()
using JukaiNLP

trainfile = "corpus/wsj_02-21.conll"
testfile = "corpus/wsj_23.conll"

JukaiNLP.readconll(trainfile)
