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
