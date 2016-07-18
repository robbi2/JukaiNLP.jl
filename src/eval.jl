function evaluate(ss::Vector{State})
    ignore = ["''", ",", ".", ":", "``", "''"]
    num, den = 0, 0
    for s in ss
        pred = heads(s)
        gold = heads(s.sent)
        @assert length(pred) == length(gold)
        for i in 1:length(pred)
            s.sent[i].wordstr in ignore && continue
            den += 1
            pred[i] == gold[i] && (num += 1)
        end
    end
    uas = float(num) / float(den)
    @printf "UAS: %1.4f\n" uas
end
