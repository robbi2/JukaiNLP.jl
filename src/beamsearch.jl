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
