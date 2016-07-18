type Token
  id::Int
  pos::Int
  form
  formid::Int
  catid::Int
  headid::Int
end

const nulltoken = Token(0, 0, "null", 0, 0, 0)

function Token(; id=0, pos=0, form="form", formid=0, catid=0, headid=0)
  Token(id, pos, form, formid, catid, headid)
end

function to_dict(t::Token)
  Dict(
    "id" => t.id,
    "pos" => t.pos,
    "form" => t.form,
    "cat" => t.cat,
    "head" => t.head)
end

function readconll(path, dicts)
  doc = Vector{Token}[]
  tokens = Token[]
  for line in open(readlines, path)
    line = chomp(line)
    if length(line) == 0
      length(tokens) > 0 && push!(doc, tokens)
      tokens = Token[]
    else
      items = split(line, '\t')
      id = parse(Int, items[1])
      form = items[2]
      form0 = replace(form, r"[0-9]", '0') |> lowercase
      formid = get!(dicts[1], form0, length(dicts[1])+1)
      catid = get!(dicts[2], items[5], length(dicts[2])+1)
      headid = parse(Int, items[7])
      t = Token(id, 0, form, formid, catid, headid)
      push!(tokens, t)
    end
  end
  length(tokens) > 0 && push!(doc, tokens)
  doc
end
readconll(path) = readconll(path, [Dict(),Dict()])

function readdict(path)
  dict = Dict()
  for line in open(readlines, path)
    get!(dict, chomp(line), length(dict)+1)
  end
  dict
end

function readtsv(path)
  doc = Vector{Vector{AbstractString}}[]
  sent = Vector{AbstractString}[]
  lines = open(readlines, path)
  for line in lines
    line = chomp(line)
    if length(line) == 0
      length(sent) > 0 && push!(doc, sent)
      sent = Vector{AbstractString}[]
    else
      items = split(line, '\t')
      push!(sent, items)
    end
  end
  length(sent) > 0 && push!(doc, sent)
  doc
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
