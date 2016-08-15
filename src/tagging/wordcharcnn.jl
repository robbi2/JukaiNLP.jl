type WordCharCNN
  wordfun
  charfun
  sentfun
end

function WordCharCNN()
    T = Float32
    wordfun = Embedding(T, 500000, 100)
    embed = Embedding(T, 100, 10)
    conv = Conv(T, (10,5), (1,50), paddims=(0,2))
    charfun = @graph (:x,) begin
        x = :x
        x = embed(x)
        x = conv(x)
        x = reshape(x, size(x,2), size(x,3))
        x = transpose(x)
        x = max(x, 2)
        x
    end
    conv = Conv(T, (150,5), (1,300), paddims=(0,2))
    linear = Linear(T, 300, 45)
    sentfun = @graph (:x,) begin
        x = :x
        x = conv(x)
        x = reshape(x, size(x,2), size(x,3))
        x = transpose(x)
        x = relu(x)
        x = linear(x)
        x
    end
    WordCharCNN(wordfun, charfun, sentfun)
end

@compat function (f::WordCharCNN)(tokens::Vector{Token})
    word_vec = map(t -> t.word, tokens)
    word_vec = reshape(word_vec, 1, length(word_vec))
    word_mat = f.wordfun(Var(word_vec))

    char_vecs = map(tokens) do t
        char_vec = reshape(t.chars, 1, length(t.chars))
        f.charfun(Var(char_vec))
    end
    char_mat = concat(2, char_vecs)

    x = concat(1, word_mat, char_mat)
    f.sentfun(x)
end
