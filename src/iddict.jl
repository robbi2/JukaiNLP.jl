export IdDict
export load

"""
    IdDict{T}

A dictionary for converting key::T into integer id.

## 👉 Example
```julia
dict = IdDict{AbstractString}()
push!(dict, "abc") == 1
push!(dict, "def") == 2
push!(dict, "abc") == 1
dict["abc"] == 1

getkey(dict, id1) == "abc"

count(dict, id1) == 2
```
"""
type IdDict{T}
    key2id::Dict{T,Int}
    id2key::Vector{T}
    id2count::Vector{Int}

    IdDict() = new(Dict{T,Int}(), T[], Int[])
end
IdDict() = IdDict{Any}()

function load{T}(::Type{IdDict{T}}, path)
    d = IdDict{T}()
    for line in open(readlines, path)
        push!(d, T(chomp(line)))
    end
    d
end

Base.count(d::IdDict, id::Int) = d.id2count[id]

Base.getkey(d::IdDict, id::Int) = d.id2key[id]

Base.getindex(d::IdDict, key) = d.key2id[key]

Base.get(d::IdDict, key, default::Int=0) = get(d.key2id, key, default)

Base.length(d::IdDict) = length(d.key2id)

function Base.push!(d::IdDict, key)
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
