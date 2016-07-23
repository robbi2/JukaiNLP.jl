
typealias Doc Vector{Vector{Token}}

function train!(parser::DepParser, trainsents::Doc,
    testsents::Doc=Vector{Token}[]; beamsize=10, iter=20, progbar=true)
    info("LOADING SENTENCES")
    info("WILL RUN $iter ITERATIONS")
    for i = 1:iter
        info("ITER $i TRAINING")
        progbar && ( p = Progress(length(trainsents), 1, "", 50) )
        res = map(trainsents) do s
            next!(p)
            s = State(s, parser)
            gold = beamsearch(s, 1, expandgold)
            pred = beamsearch(s, beamsize, expandpred)
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

function train!(parser::DepParser, trainfile::AbstractString,
    testfile::AbstractString=""; beamsize=10, iter=20, progbar=true)
    trainsents = readconll(parser, trainfile)
    testsents = testfile == "" ? Vector{Token}[] : readconll(parser, testfile)
    train!(parser, trainsents, testsents,
        beamsize=beamsize, iter=iter, progbar=progbar)
end

function decode(parser::DepParser, sents::Doc; beamsize=10, progbar=true)
    progbar && ( p = Progress(length(sents), 1, "", 50) )
    map(sents) do s
        progbar && next!(p)
        pred = State(s, parser)
        beamsearch(pred, beamsize, expandpred)
    end
end

function decode(parser::DepParser, sentfile::AbstractString; beamsize=10, progbar=true)
    sents = readconll(parser, sentfile)
    decode(parser, sents, beamsize=beamsize, progbar=progbar)
end
