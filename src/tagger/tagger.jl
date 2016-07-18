type POSTagger
  word_dict
  char_dict
  tag_dict
  nn
end

module Tagger
include("token.jl")
end

function POSTagger()
  word_dict = readdict("$(JUKAI_ENV["DICT_PATH"])/en-word_nyt.dict")
  char_dict = readdict("$(JUKAI_ENV["DICT_PATH"])/en-char.dict")
  nn = NN()
  POSTagger(word_dict, char_dict, IdDict(), nn)
end

function Token2(p::POSTagger, str)
  word = replace(str, r"[0-9]", '0')
  wordid = get(p.word_dict, lowercase(word), 1)
  chars = convert(Vector{Char}, word)
  charids = map(c -> get(char_dict,string(c),1), chars)
  (wordid, charids)
end

function trim(p::POSTagger, tokens::Vector{Token})
  id2word = Dict()
  counter = fill(0, length(p.word_dict))
  for (k,v) in p.word_dict
    id2word[v] = k
    counter[v] += 1
  end
  for i = 1:length(counter)
    c = counter[i]
    if c == 0
      p.nn.wordfun.weights[i] = Variable()
      delete!(p.word_dict, id2word[i])
    end
  end
end

function decode(p::POSTagger, x::Vector{Token})
  y = p.nn(x)
  argmax(y.value, 1)
end

function decode!(p::POSTagger, doc::Vector{Vector{Jukai.Token}})
  for tokens in doc
    x = map(tokens) do t
      Token(t.form, p.word_dict, p.char_dict)
    end
    tags = decode(p, x)
    for i = 1:length(tags)
      tokens[i].cat = p.tag_dict.idkey[tags[i]]
    end
  end
end

function readdata(t::POSTagger, path)
  doc = readtsv(path)
  data_x, data_y = Vector{Token}[], Vector{Int}[]
  for sent in doc
    push!(data_x, Token[])
    push!(data_y, Int[])
    for items in sent
      tok = Token(items[2], t.word_dict, t.char_dict)
      tag = items[5]
      tagid = add!(t.tag_dict, tag)
      push!(data_x[end], tok)
      push!(data_y[end], tagid)
    end
  end
  data_x, data_y
end

function train(p::POSTagger, trainpath, testpath)
  train_x, train_y = readdata(p, trainpath)
  test_x, test_y = readdata(p, testpath)
  #train_x = train_x[1:5000]
  #train_y = train_y[1:5000]
  # remove unused word (messy)
  tokens = Token[]
  for data in (train_x, test_x)
    for x in data
      for t in x
        push!(tokens, t)
      end
    end
  end
  #trim(p, tokens)

  for epoch = 1:3
    println("epoch: $(epoch)")
    p.nn.opt.rate = 0.0075 / epoch
    loss = fit(p.nn, train_x, train_y)
    println("training loss: $(loss)")
    zs = map(x -> decode(p,x), test_x)
    acc = accuracy(test_y, zs)
    println("test acc.: $(acc)")
    println("")
  end
  println("training finish.")
end
