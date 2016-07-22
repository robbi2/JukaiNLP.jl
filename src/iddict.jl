"""
    IdDict{T}

A dictionary for converting item::T into integer id.

## 👉 Example
```julia
dict = IdDict{AbstractString}()
id1 = push!(dict, "abc")
id2 = push!(dict, "def")
id3 = push!(dict, "abc")
```
"""
type IdDict{T}
    key2id::Dict{T,Int}
    id2key::Vector{T}
    id2count::Vector{Int}

    IdDict() = new(Dict{T,Int}(), T[], Int[])
end
IdDict() = IdDict{Any}()

"""
    IdDict(path)

Construct IdDict from a file.
"""
function IdDict(T::Type, path)
    d = IdDict{T}()
    for line in open(readlines, path)
        push!(d, T(chomp(line)))
    end
    d
end

Base.count(d::IdDict, id::Int) = d.id2count[id]

Base.getkey(d::IdDict, id::Int) = d.id2key[id]

Base.getindex{T}(d::IdDict{T}, key::T) = d.key2id[key]

Base.get{T}(d::IdDict{T}, key::T, default=0) = get(d.key2id, key, default)

Base.length(d::IdDict) = length(d.key2id)

function Base.push!{T}(d::IdDict{T}, key::T)
    if haskey(d.key2id, key)
        id = d.key2id[key]
        d.id2count[id] += 1
    else
        id = length(d.key2id) + 1
        d.key2id[key] = id
        push!(d.id2key, key)
        push!(d.id2count, 1)
    end
    id
end
