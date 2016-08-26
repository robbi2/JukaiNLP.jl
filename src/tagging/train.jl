function train(t::Tagger, nepochs::Int, traindata::Vector, testdata::Vector)
    data_x, data_y = encode(t, traindata)
    test_x = map(x -> map(xx -> xx[1], x), testdata)
    pred_y = Int[]
    for x in testdata
        for items in x
            push!(pred_y, t.tag_dict[items[2]])
        end
    end

    info("# words: $(length(t.word_dict))")
    info("# chars: $(length(t.char_dict))")
    info("# tags: $(length(t.tag_dict))")

    opt = SGD(0.001, momentum=0.0)
    for epoch = 1:nepochs
        opt.rate = 0.0075 / epoch
        #opt.rate = 0.0075 / epoch
        #data_xx = setunkown(data_x, t.word_dict["UNKNOWN"])

        println("epoch: $(epoch)")
        loss = fit(t.model, crossentropy, opt, data_x, data_y)
        println("loss: $(loss)")

        pred_z = Int[]
        for x in test_x
            append!(pred_z, t(x))
        end
        acc = accuracy(pred_y, pred_z)

        println("test acc.: $(acc)")
        println("")
    end
end

function encode(t::Tagger, doc::Vector)
    data_x, data_y = Vector{Token}[], Vector{Int}[]
    for sent in doc
        push!(data_x, Token[])
        push!(data_y, Int[])
        for items in sent
            word, tag = items[1], items[2]
            word0 = replace(word, r"[0-9]", '0') |> lowercase
            #wordid = push!(t.word_dict, word0)

            wordid = get(t.word_dict, word0, 1) # experimental

            chars = Vector{Char}(word)
            charids = map(c -> push!(t.char_dict,string(c)), chars)
            tagid = push!(t.tag_dict, tag)
            token = Token(wordid, charids)
            push!(data_x[end], token)
            push!(data_y[end], tagid)
        end
    end
    data_x, data_y
end

function accuracy(golds::Vector{Int}, preds::Vector{Int})
    @assert length(golds) == length(preds)
    correct = 0
    total = 0
    for i = 1:length(golds)
        golds[i] == preds[i] && (correct += 1)
        total += 1
    end
    correct / total
end
