function decode(t::Tokenizer, x::Vector{Int})
  x = reshape(x, 1, length(x))
  y = t.nn(:x=>x)
  argmax(y.value, 1)
end

function decode(t::Tokenizer, chars::Vector{Char})
  unk = t.dict["UNKNOWN"]
  x = map(chars) do c
    get(t.dict, string(c), unk)
  end
  decode(t, x)
end

function tokenize(chars::Vector{Char}, tags::Vector{Int})
  length(chars) == length(tags) || throw("Length unmatch")
  Token = Jukai.Token
  doc = Vector{Token}[]
  tokens = Token[]
  buffer = Char[]
  pos = 1
  function push_buffer!(i::Int)
    push!(buffer, chars[i])
  end
  function push_token!()
    length(buffer) == 0 && return
    form = convert(AbstractString, buffer)
    t = Token(pos=pos, form=form)
    push!(tokens, t)
    pos += length(buffer) + 1
    buffer = Char[]
  end
  function push_tokens!()
    length(tokens) == 0 && return
    push!(doc, tokens)
    tokens = Token[]
  end

  for i = 1:length(chars)
    t = tags[i]
    if t == 1
      push_buffer!(i)
    elseif t == 2
      continue
    elseif t == 3
      push_buffer!(i)
      push_token!()
    elseif t == 4
      push_buffer!(i)
      push_token!()
      push_tokens!()
    else
      error("Invalid tag: $(t)")
    end
  end
  push_token!()
  push_tokens!()
  doc
end
