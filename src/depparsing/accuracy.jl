#=
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
=#

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
