function encode(t::Tokenizer, doc::Vector)
    unk, space, lf = t.dict["UNKNOWN"], t.dict[" "], t.dict["\n"]
    chars = Int[]
    ranges = UnitRange{Int}[]
    pos = 1
    for sent in doc
        for (word,tag) in sent
            for c in tag
                c == '_' && continue
                if c == 'S' # space
                    push!(chars, space)
                elseif c == 'N' # newline
                    push!(chars, lf)
                end
                pos += 1
            end
            for c in word
                push!(chars, push!(t.dict,string(c)))
            end
            push!(ranges, pos:pos+length(word)-1)
            pos += length(word)
        end
    end
    chars, ranges
end

function train(t::Tokenizer, nepochs::Int, doc::Vector)
    chars, ranges = encode(t, doc)
    tags = encode(t.tagset, ranges)
    data_x, data_y = [], []
    push!(data_x, chars)
    push!(data_y, tags)

    #opt = AdaGrad(0.01)
    opt = SGD(0.0001, momentum=0.9)
    for epoch = 1:nepochs
        println("epoch: $(epoch)")
        loss = fit(t.model, crossentropy, opt, data_x, data_y)
        println("loss: $(loss)")

        data_z = map(data_x) do x
            argmax(t.model(x).data, 1)
        end
        data_yy, data_zz = [data_y...], [data_z...]
        c = count(x -> x[1] == x[2], zip(data_yy,data_zz))
        acc = c / length(data_yy)

        println("test acc.: $(acc)")
        println("")
    end
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
