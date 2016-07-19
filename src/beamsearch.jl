"""
    beamsearch

Requirements of T:
* member: score
* member: step
"""
function beamsearch{T}(initstate::T, beamsize::Int, expand::Function)
    chart = Vector{T}[]
    push!(chart, [initstate])
    lessthan{T}(x::T, y::T) = x.score > y.score

    k = 1
    while k <= length(chart)
        states = chart[k]
        length(states) > beamsize && sort!(states, lt=lessthan)
        for i = 1:min(beamsize, length(states))
            for s in expand(states[i])
                while s.step > length(chart)
                    push!(chart, T[])
                end
                push!(chart[s.step], s)
            end
        end
        k += 1
    end
    sort!(chart[end], lt=lessthan)
    chart[end][1]
end

function to_seq{T}(finalstate::T)
    seq = T[]
    s = finalstate
    # while s != nothing
    while s.step > 1
        unshift!(seq, s)
        s = s.prev
    end
    unshift!(seq, s)
    seq
end

"""
    max_violation!

Ref: L. Huang et al, "Structured Perceptron with Inexact Seatch", ACL 2012.
"""
function max_violation!{T}(gold::T, pred::T, train_gold, train_pred)
    goldseq, predseq = to_seq(gold), to_seq(pred)
    maxk, maxv = 1, 0.0
    for k = 1:length(goldseq)
        v = predseq[k].score - goldseq[k].score
        if k == 1 || v >= maxv
            maxk = k
            maxv = v
        end
    end
    # println("maxk: $(maxk) of $(length(goldseq))")
    for k = 2:maxk
        train_gold(goldseq[k])
        train_pred(predseq[k])
    end
end

#=
st_lessthan(x::State, y::State) = y.score < x.score

function beamsearch(beamsize::Int, initstate::State, expand::Function)
    chart = Vector{State}[[initstate]]
    i = 1
    while i <= length(chart)
        states = chart[i]
        length(states) > beamsize && sort!(states, lt=st_lessthan)
        for j = 1:min(beamsize, length(states))
            for s in expand(states[j])
                while s.step > length(chart) push!(chart, []) end
                push!(chart[s.step], s)
            end
        end
        i += 1
    end
    sort!(chart[end], lt=st_lessthan)
    chart[end][1]
end

function state2array(s::State)
    res = Vector{State}(s.step)
    st = s
    while st.step > 1
        res[st.step] = st
        st = st.prev
    end
    res[st.step] = st
    res
end

function maxviolate!(gold::State, pred::State)
    golds = state2array(gold)
    preds = state2array(pred)
    maxv  = typemin(Float); maxk = 1
    for k = 2:min(length(golds), length(preds))
        v = preds[k].score - golds[k].score
        if v >= maxv
            maxv, maxk = v, k
        end
    end
    for i = 2:maxk
        traingold!(model, golds[i])
        trainpred!(model, preds[i])
    end
end
=#
