
function train(iter::Int=20)
    info("LOADING SENTENCES")
    readworddict!(wordspath)
    trainsents = readconll(trainpath)
    testsents  = readconll(testpath)
    model = Perceptron(zeros(1<<26,4))
    output = open("output", "w")

    info("WILL RUN $iter ITERATIONS")
    for i = 1:iter
        info("ITER $i TRAINING")
        p = Progress(length(trainsents), 1, "", 50)
        map(trainsents) do s
            next!(p)
            s = State(s, model)
            gold = beamsearch(s, 1, expandgold)
            pred = beamsearch(s, 10, expandpred)
            max_violation!(gold, pred,
                s -> traingold!(model, s), s -> trainpred!(model, s))
            pred
        end |> evaluate

        info("ITER $i TESTING")
        p = Progress(length(testsents), 1, "", 50)
        map(testsents) do s
            next!(p)
            pred = State(s, model)
            pred_out = beamsearch(pred, 10, expandpred)
            toconll(output, pred_out)
            pred_out
        end |> evaluate
    end
    close(output)
end
