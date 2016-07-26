function train(t::Tokenizer, nepochs::Int, path::String)
    chars, ranges = readfile(path, t.dict)
    tags = encode(t.tagset, ranges)

    data_x = []
    push!(data_x, chars)
    data_y = []
    push!(data_y, tags)
    opt = SGD(0.0001)
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
