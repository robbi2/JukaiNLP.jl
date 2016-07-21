type IdDict{T}
  keyid::Dict{T,Int}
  idkey::Vector{T}
  idcount::Vector{Int}
end

IdDict{T}(::Type{T}) = IdDict(Dict{T,Int}(), T[], Int[])
IdDict() = IdDict(Any)

function IdDict(path)
  d = IdDict(AbstractString)
  for line in open(readlines, path)
    add!(d, chomp(line))
  end
  d
end

Base.getindex{T}(d::IdDict{T}, key::T) = d.keyid[key]
Base.get{T}(d::IdDict{T}, item::T, default=0) = get(d.keyid, item, default)

function Base.get!{T}(d::IdDict{T}, item::T)
  haskey(d.keyid, item) || add!(d, item)
  d.keyid[item]
end

Base.length(d::IdDict) = length(d.keyid)

function add!{T}(d::IdDict{T}, item::T)
  if haskey(d.keyid, item)
    id = d.keyid[item]
    d.idcount[id] += 1
  else
    id = length(d.keyid) + 1
    d.keyid[item] = id
    push!(d.idkey, item)
    push!(d.idcount, 1)
  end
  id
end

getcount{T}(d::IdDict{T}, id::Int) = d.idcount[id]

function trim!{T}(d::IdDict{T})
  for i = 1:length(d.idkey)
    c = d.idcount[i]
    c == 0 && delete!(d.keyid, d.idkey[i])
  end
end
