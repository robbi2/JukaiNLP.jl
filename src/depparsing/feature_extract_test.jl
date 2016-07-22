
macro test(cond)
    teststr = string(cond)
    quote
        println("TEST: ", $teststr)
        $(esc(cond)) ? println(" -> OK") : throw("Error")
    end
end

push!(LOAD_PATH, "src")
using JukaiNLP: Perceptron, DepParser, readconll
using JukaiNLP.DepParsing: expandgold, State, isfinal, tokenat, stacktrace
using TransitionParser: beamsearch

parser = DepParser("dict/en-word_nyt.dict", Perceptron(zeros(100, 3)))
sents = readconll(parser, "corpus/mini-training-set.conll")
s = beamsearch(State(sents[1], parser.model), 1, expandgold)
# stacktrace(parser, s)

tostr = parser.words.idkey

@test isfinal(s)
@test tokenat(s, s.top).word == 0
@test tostr[tokenat(s, s.rchild).word] == "knew"
@test tostr[tokenat(s, :rchild, :rchild).word] == "."
@test tostr[tokenat(s, :rchild, :lchild).word] == "i"
@test tostr[tokenat(s, :rchild, :rsibl, :rchild).word] == "do"
@test tostr[tokenat(s, :rchild, :rsibl, :rchild, :lchild).word] == "i"
@test tostr[tokenat(s, :rchild, :rsibl, :rchild, :lsibl, :lchild).word] == "could"
@test tostr[tokenat(s, :rchild, :rsibl, :rchild, :rsibl, :rchild).word] == "properly"
@test tostr[tokenat(s, :rchild, :rsibl, :rchild, :rsibl, :rsibl, :rchild).word] == "it"
@test tostr[tokenat(s, :rchild, :rsibl, :rchild, :rchild).word] == "given"
@test tostr[tokenat(s, :rchild, :rsibl, :rchild, :rchild, :lchild).word] == "if"
@test tostr[tokenat(s, :rchild, :rsibl, :rchild, :rchild, :rchild).word] == "kind"
@test tostr[tokenat(s, :rchild, :rsibl, :rchild, :rchild, :rchild, :lchild).word] == "the"
@test tostr[tokenat(s, :rchild, :rsibl, :rchild, :rchild, :rchild, :lsibl, :lchild).word] == "right"
@test tostr[tokenat(s, :rchild, :rsibl, :rchild, :rchild, :rchild, :rchild).word] == "of"
@test tostr[tokenat(s, :rchild, :rsibl, :rchild, :rchild, :rchild, :rchild, :rchild).word] == "support"
