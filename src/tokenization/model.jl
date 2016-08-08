type CNNModel
    embed
    conv
    linear
end

function CNNModel()
    T = Float32
    embed = Embedding(T,100,10)
    conv = Conv(T, (10,7), (1,70), paddims=(0,3))
    linear = Linear(T,70,4)
    CNNModel(embed, conv, linear)
end

@compat function (m::CNNModel)(chars::Vector{Int})
    x = Var(reshape(chars,1,length(chars)))
    x = m.embed(x)
    x = m.conv(x)
    x = reshape(x, size(x,2), size(x,3))
    x = transpose(x)
    x = relu(x)
    x = m.linear(x)
    x
end
