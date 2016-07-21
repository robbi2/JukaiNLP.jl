function train(t::Tokenizer, path)
    train_x, train_y = readconll(t, path)
    test_x = train_x
    test_y = map(y -> y.data, train_y)
    opt = SGD(0.0001)
    for epoch = 1:20
        println("epoch: $(epoch)")
        loss = fit(t.nn, crossentropy, opt, train_x, train_y)
        println("loss: $(loss)")
        zs = map(x -> decode(t,x), test_x)
        acc = accuracy(test_y, zs)
        println("test acc.: $(acc)")
        println("")
    end
    println("training finish.")
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

function accuracy(golds::Vector{Vector{Int}}, preds::Vector{Vector{Int}})
    @assert length(golds) == length(preds)
    correct = 0
    total = 0
    for i = 1:length(golds)
        for j = 1:length(golds[i])
            golds[i][j] == preds[i][j] && (correct += 1)
            total += 1
        end
    end
    correct / total
end
