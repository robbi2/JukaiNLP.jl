
abstract Model

type Perceptron  <: Model
    weights::Matrix{Float64}
end

@compat function (p::Perceptron)(s::State, act::Int)
    if !isdefined(s, :feat)
        s.feat = featuregen(s)
    end
    res = 0.0
    for f in s.feat
        res += p.weights[f,act]
    end
    res
end

function traingold!(p::Perceptron, s::State)
    act = s.prevact
    feat = s.prev.feat
    for f in feat
        p.weights[f,act] += 1.0
    end
end

function trainpred!(p::Perceptron, s::State)
    act = s.prevact
    feat = s.prev.feat
    for f in feat
        p.weights[f,act] -= 1.0
    end
end
