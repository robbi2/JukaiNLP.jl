type WordCharCNN
  wordfun
  charfun
  sentfun
end

function WordCharCNN{T}(::Type{T})
    wordfun = Lookup(F, 500000, 100)
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
