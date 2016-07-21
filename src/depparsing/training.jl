
function train!(parser::DepParser, trainsents, testsents=[]; iter=20, progbar=true)
    info("LOADING SENTENCES")
    info("WILL RUN $iter ITERATIONS")
    for i = 1:iter
        info("ITER $i TRAINING")
        progbar && ( p = Progress(length(trainsents), 1, "", 50) )
        res = map(trainsents) do s
            next!(p)
            s = State(s, parser.model)
            gold = beamsearch(s, 1, expandgold)
            pred = beamsearch(s, 10, expandpred)
            max_violation!(gold, pred,
                s -> traingold!(parser.model, s),
                s -> trainpred!(parser.model, s))
            pred
        end
        evaluate(parser, res)

        if !isempty(testsents)
            info("ITER $i TESTING")
            res = decode(parser, testsents)
            evaluate(parser, res)
        end
    end
end

function decode(parser::DepParser, sents; progbar=true)
    progbar && ( p = Progress(length(sents), 1, "", 50) )
    map(sents) do s
        progbar && next!(p)
        pred = State(s, parser.model)
        beamsearch(pred, 10, expandpred)
    end
end
