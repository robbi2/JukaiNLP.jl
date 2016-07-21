function evaluate(parser::DepParser, ss::Vector{State})
    ignore = map(w -> parser.words[w], ["''", ",", ".", ":", "``", "``"])
    num, den = 0, 0
    for s in ss
        pred = heads(s)
        gold = map(t -> t.head, s.tokens)
        @assert length(pred) == length(gold)
        for i in 1:length(pred)
            s.tokens[i].word in ignore && continue
            den += 1
            pred[i] == gold[i] && (num += 1)
        end
    end
    uas = float(num) / float(den)
    @printf "UAS: %1.4f\n" uas
end
