type POSModel
    wordfun
    charfun
    sentfun
end

function POSModel(path)
    T = Float32
    #wordfun = Embedding(T, 500000, 100)
    path = "C:/Users/hshindo/Dropbox/tagging/nyt100.lst"
    wordfun = Embedding(path, T)
    charfuns = [Embedding(T,100,10), Linear(T,50,50)]
    charfun = @graph (:x,) begin
        x = charfuns[1](:x)
        x = window2d(x, 10,5,1,1,0,2)
        x = charfuns[2](x)
        x = max(x,2)
        x
    end

    sentfuns = [Linear(T,750,300), Linear(T,300,45)]
    sentfun = @graph (:wordmat,:charmat) begin
        x = concat(1, :wordmat, :charmat)
        x = window2d(x, 150,5,1,1,0,2)
        x = sentfuns[1](x)
        x = relu(x)
        x = sentfuns[2](x)
        x
    end
  #word_f = Lookup("$(path)/nyt100.lst", T)
  #char_f = [Lookup(T,100,10),
    #        Window2D(10,5,1,1,0,2),
    #        Linear(T,50,50),
    #        Max(2)]
  #sent_f = [Window2D(150,5,1,1,0,2),
    #        Linear(T,750,300),
    #        ReLU(),
    #        Linear(T,300,45)]
  #POSModel(word_f, char_f, sent_f)
    POSModel(wordfun, charfun, sentfun)
end

@compat function (m::POSModel)(tokens::Vector{Token})
    word_vec = map(t -> t.word, tokens)
    wordvec = reshape(word_vec, 1, length(word_vec))
    wordmat = m.wordfun(Var(wordvec))

    charvecs = map(tokens) do t
        charvec = reshape(t.chars, 1, length(t.chars))
        m.charfun(Var(charvec))
    end
    charmat = concat(2, charvecs)
    m.sentfun(wordmat, charmat)
end
