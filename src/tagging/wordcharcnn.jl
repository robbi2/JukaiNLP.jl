type WordCharCNN
  wordfun
  charfun
  sentfun
end

function WordCharCNN{T}(::Type{T})
    #wordfun = Embed(F, 500000, 100)
    #wordfun = Lookup(path, F)
    #=
    charfun = @graph begin
        Lookup(T,100,10),
        Window2D(10,5,1,1,0,2),
        Linear(F,50,50),
        Max(2)
    end
    sentfun = @graph begin
        Window2D(150,5,1,1,0,2),
        Linear(F,750,300),
        ReLU(),
        Linear(F,300,45))
        WordCharCNN(wordfun, charfun, sentfun)
    end
    =#
end

@compat function (f::WordCharCNN)(tokens::Vector{Token})
  word_vec = map(t -> t.word, tokens)
  word_vec = reshape(word_vec, 1, length(word_vec))
  word_mat = nn.wordfun(word_vec)

  char_vecs = map(tokens) do t
    char_vec = reshape(t.chars, 1, length(t.chars))
    nn.charfun(char_vec)
  end
  char_mat = Concat(2)(char_vecs)
  (word_mat, char_mat) |> Concat(1) |> nn.sentfun
end

type POSModel
  word_f
  char_f
  sent_f
end

function POSModel()
  T = Float32
  word_embed = Embed(T,500000,100)
  char_embed = Embed(T,100,10)
  char_conv = Conv(T)
  word_conv = Conv(T)
  word_out = Linear(T,300,45)

  word_f = Lookup(T, 500000, 100)
  char_f = @graph begin
    x = Var(:x)
    x = Lookup(T,100,10)(x)
    Window2D(10,5,1,1,0,2)
    x = Linear(T,50,50)(x)
    x = max(x,2)
    x
  end
  sent_f = @graph begin
    Window2D(150,5,1,1,0,2)
    Linear(T,750,300)
    x = relu(x)
    x = Linear(T,300,45)(x)
    x
  end
  Model(word_f, char_f, sent_f)
end

@compat function (m::POSModel)(tokens::Vector{Token})
    wordvec = map(t -> t.wordid, tokens)
    wordvec = reshape(wordvec,1,length(wordvec))
    wordmat = m.word_embed(wordvec)
    charvecs = map(tokens) do t
      charvec = reshape(t.charids,1,length(t.charids))
      x = m.char_embed(charvec)
      x = m.char_conv(x)
      x = max(x,2)
      x
    end
    charmat = concat(2, charvecs)
    x = concat(1,wordmat,charmat)
    x = m.word_conv(x)
    x = relu(x)
    x = m.out(x)
    x
end
