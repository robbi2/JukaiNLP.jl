
function getval(x::Var, i::Int)
    y = x.data[i, :]
    function df{T}(gy::UniArray{T})
        @inbounds @simd for j = 1:length(y)
            gx.grad[i, j] += gy[j]
        end
    end
    Var(y, [x], df)
end
