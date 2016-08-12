
"""
A Fast and Accurate Dependency Parser using Neural Networks, Chen and Manning, EMNLP 2014
"""

type Sample
    wordids::Vector{Int}
    tagids::Vector{Int}
    labelids::Vector{Int}
    target::Int
end

type FeedForward
    word_f
    tag_f
    label_f
    W
end

targetsize(m::FeedForward) = size(m.W[end].w.data)[1]

# tentative
function myEmbed{T}(path::AbstractString, t::Type{T})
    lines = open(readlines, path)
    ws = Array(Var, length(lines))
    for i = 1:length(lines)
        items = split(chomp(lines[i]), ' ')
        w = map(x -> parse(T,x), items)
        ws[i] = Merlin.Param(w)
    end
    Embedding(ws, IntSet())
end

# linear function with [-0.01, 0.01] uniform distribution
function myLinear(T::Type, indim::Int, outdim::Int)
    r = T(0.01)
    w = rand(-r, r, outdim, indim)
    b = fill(T(0), outdim, 1)
    Linear(Merlin.Param(w),Merlin.Param(b))
end

function initmodel!(parser::DepParser, model::Type{FeedForward}; embed="",
    sparsesizes=[20,20,12] ,embedsizes=[50,50,50], hiddensizes=[1024])
    T = Float32
    if embed == ""
        info("USING EMBEDDINGS WITH UNIFORM DISTRIBUTION [-0.01, 0.01]")
        word_f = Embedding(T, length(parser.words), embedsizes[1])
    else
        info("USING EMBEDDINGS LOADED FROM $(embed)")
        word_f = myEmbed(embed, Float32)
    end
    tag_f = Embedding(T, length(parser.tags), embedsizes[2])
    label_f = Embedding(T, length(parser.labels), embedsizes[3])
    indim = sum(sparsesizes .* embedsizes)
    outdim = 1 + 2 * length(parser.labels)
    W = Array(Linear, length(hiddensizes)+1)
    for i = 1:length(hiddensizes)
        W[i] = myLinear(T, indim, hiddensizes[i])
        indim = hiddensizes[i]
    end
    W[end] = myLinear(T, indim, outdim)
    parser.model = FeedForward(word_f, tag_f, label_f, W)
    info("INPUT: [S^word,S^tag,S^label] = ", sparsesizes)
    info("EMBED DIMS: [word,tag,label] = ", embedsizes)
    info("HIDDEN LAYER: ", hiddensizes)
    info("OUTPUT DIM: ", outdim)
end

# TODO: make State have id field
# to tell where the State is in a batch
# called from expand(::State ::Int)
@compat function (m::FeedForward){T}(s::State{T}, act::Int)
    Var([0f0])
end

@compat function (m::FeedForward)(batch::AbstractVector{Sample})
    wordvec, tagvec, labelvec = [], [], []
    for s in batch
        push!(wordvec, s.wordids)
        push!(tagvec, s.tagids)
        push!(labelvec, s.labelids)
    end
    wordmat = m.word_f(Var(hcat(wordvec...)))
    tagmat = m.tag_f(Var(hcat(tagvec...)))
    labelmat = m.label_f(Var(hcat(labelvec...)))
    h0 = concat(1, wordmat, tagmat, labelmat)
    h1 = tanh(m.W[1](h0))
    # h2 = tanh(m.W[2](h1))
    m.W[end](h1)
end

@compat function (m::FeedForward){T}(batch::AbstractVector{State{T}})
    batch = map(batch) do s
        w, t, l = sparsefeatures(s)
        Sample(w, t, l, -1)
    end
    m(batch)
end

function sparsefeatures(s::State)
    if isfinal(s)
        return fill(1, 20), fill(1, 20), fill(1, 12)
    end

    # word, tag
    b0 = tokenat(s, s.right)
    b1 = tokenat(s, s.right + 1)
    b2 = tokenat(s, s.right + 2)
    b3 = tokenat(s, s.right + 3)
    s0 = tokenat(s, s.top)
    s0l = tokenat(s, s.lchild)
    s0l2 = tokenat(s, s.lsibl.lchild)
    s0r = tokenat(s, s.rchild)
    s0r2 = tokenat(s, s.rsibl.rchild)
    s02l = tokenat(s, s.lchild.lchild)
    s12r = tokenat(s, s.rchild.rchild)
    s1 = tokenat(s, s.left)
    s1l = tokenat(s, s.left.lchild)
    s1l2 = tokenat(s, s.left.lsibl.lchild)
    s1r = tokenat(s, s.left.rchild)
    s1r2 = tokenat(s, s.left.rsibl.rchild)
    s12l = tokenat(s, s.left.lchild.lchild)
    s12r = tokenat(s, s.left.rchild.rchild)
    s2 = tokenat(s, s.left.left)
    s3 = tokenat(s, s.left.left.left)
    
    # labels
    s0rc_label = labelat(s, s.rchild)
    s0rc2_label = labelat(s, s.rsibl.rchild)
    s0lc_label = labelat(s, s.lsibl)
    s0lc2_label = labelat(s, s.lsibl.lsibl)
    s02l_label = labelat(s, s.lsibl.left.lsibl)
    s02r_label = labelat(s, s.rchild.rchild)
    s1rc_label = labelat(s, s.left.rchild)
    s1rc2_label = labelat(s, s.left.rsibl.rchild)
    s1lc_label = labelat(s, s.left.lsibl)
    s1lc2_label = labelat(s, s.left.lsibl.lsibl)
    s12l_label = labelat(s, s.left.lsibl.left.lsibl)
    s12r_label = labelat(s, s.rchild.rchild)

    words = [b0.word, b1.word, b2.word, b3.word, s0.word, s0l.word, s0l2.word,
    s0r.word, s0r2.word, s02l.word, s12r.word, s1.word, s1l.word, s1l2.word,
    s1r.word, s1r2.word, s12l.word, s12r.word, s2.word, s3.word]

    tags = [b0.tag, b1.tag, b2.tag, b3.tag, s0.tag, s0l.tag, s0l2.tag,
    s0r.tag, s0r2.tag, s02l.tag, s12r.tag, s1.tag, s1l.tag, s1l2.tag,
    s1r.tag, s1r2.tag, s12l.tag, s12r.tag, s2.tag, s3.tag]

    labels = [s0rc_label, s0rc2_label, s0lc_label, s0lc2_label, s02l_label,
    s02r_label, s1rc_label, s1rc2_label, s1lc_label, s1lc2_label,
    s12l_label, s12r_label]

    return words, tags, labels
end

function parsegreedy!{T}(parser::DepParser{T}, ss::Vector{State{T}})
    while !all(isfinal, ss)
        preds = parser.model(ss)
        preds.data += [isvalid(ss[j], acttype(i)) ? 0f0 : -Inf32
                       for i = 1:targetsize(parser.model), j = 1:length(ss)]
        bestacts = argmax(preds.data, 1)
        for i = 1:length(ss)
            isfinal(ss[i]) && continue
            ss[i] = expand(ss[i], bestacts[i])
        end
    end
    ss
end

function update!(opt::Union{SGD,AdaGrad}, gold::Vector{Int}, pred::Var)
    l = crossentropy(gold, pred) * (1 / length(gold))
    loss = sum(l.data)
    vars = gradient!(l)
    for v in vars
        if isa(v.f, Merlin.Functor)
            # l2 normalization
            BLAS.axpy!(Float32(10e-8), v.data, v.grad)
            Merlin.update!(v.f, opt)
        end
    end
    loss
end

typealias Doc Vector{Vector{Token}}

function train!{T}(::Type{FeedForward}, parser::DepParser{T}, trainsents::Doc,
    testsents::Doc=Vector{Token}[]; embed="", batchsize=32, iter=20, progbar=true,
    opt=SGD(0.01, 0.9), evaliter=100, outfile="parser.dat")
    # opt=AdaGrad(0.01), evaliter=100, outfile="parser.dat")
    info("WILL RUN $iter ITERATIONS")

    saver = ModelSaver(outfile)
    initmodel!(parser, FeedForward, embed=embed)
    trainsamples = map(trainsents) do s
        res = Sample[]
        s = State(s, parser)
        while !isfinal(s)
            w, t, l = sparsefeatures(s)
            s = expandgold(s)[1]
            push!(res, Sample(w, t, l, s.prevact))
        end
        res
    end
    trainsamples = vcat(trainsamples...)
    samplesize = length(trainsamples)
    labelsize = targetsize(parser.model)

    info("OPTIMIZER: ", typeof(opt))
    info("BATCH SIZE: $batchsize LABEL SIZE: $labelsize")
    info("#BATCHES: $(div(samplesize, batchsize))")
    info("#SAMPLES: $(samplesize)")

    for i = 1:iter
        info("ITER $i TRAINING")
        batch = sub(trainsamples, rand(1:samplesize, batchsize))
        preds = parser.model(batch)
        golds = map(s -> s.target, batch)
        correct = reduce(0, zip(argmax(preds.data, 1), golds)) do v, tup
            v + Int(tup[1] == tup[2])
        end
        accuracy = correct / batchsize
        loss = update!(opt, golds, preds)
        info(now())
        info("LOSS: ", loss)
        info("ACCURACY: ", accuracy)

        if i % evaliter == 0 && !isempty(testsents)
            println()
            info("**ITER $i TESTING**")
            res = decode(FeedForward, parser, testsents)
            uas, las = evaluate(parser, res)
            saver(parser, uas)
        end
        println()
    end
end

function decode{T}(::Type{FeedForward}, parser::DepParser{T}, sents::Doc;
    batchsize=32, progbar=true)
    batches = 1:batchsize:length(sents)
    res = State{T}[]
    for k in batches
        batch = k:min(k+batchsize-1, endof(sents))
        ss = map(s -> State(s, parser), sub(sents, batch))
        parsegreedy!(parser, ss)
        append!(res, ss)
    end
    res
end

