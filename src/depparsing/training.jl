function train(iter::Int=20)
    info("LOADING SENTENCES")
    trainsents = readconll(trainfile)
    testsents  = readconll(testfile)
    model = Perceptron(zeros(1<<26,4))

    info("WILL RUN $ITERATION ITERATIONS")
    for i = 1:ITERATION
        info("ITER $i TRAINING")
        p = Progress(length(v), 1, "", 50)
        map(trainsents) do s
            next!(p)
            s = State(s, model)
            gold = beamsearch(1, s, expandgold)
            pred = beamsearch(10, s, expandpred)
            maxviolate!(gold, pred)
            pred
        end |> evaluate

        info("ITER $i TESTING")
        p = Progress(length(v), 1, "", 50)
        map(testsents) do s
            next!(p)
            pred = State(s, model)
            beamsearch(10, pred, expandpred)
        end |> evaluate
    end
end
