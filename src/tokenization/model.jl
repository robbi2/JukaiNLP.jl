type Model
    embed
    conv
    linear
end

function Model()
    T = Float32
    Model(Embed(T,100,10),
        Conv(T,(10,7),(1,70),paddims=(0,3)),
        Linear(T,70,4))
end

@compat function (m::Model)(input::Vector{Int})
    x = Var(reshape(input,1,length(input)))
    x = m.embed(x)
    x = m.conv(x)
    x = reshape(x, size(x,2), size(x,3))
    x = relu(x)
    x = m.linear(x.')
    x
end
