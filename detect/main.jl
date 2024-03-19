using Colors, ColorVectorSpace
using FixedPointNumbers
const CoN0 = RGB{N0f8}

function classify(v, colors)
    indices = partialsortperm(v, 1:10, by = x -> Gray(x))
    ss = zeros(length(colors))
    for (i, color) in enumerate(colors), j in indices
        ss[i] += colordiff(color, v[j])
    end
    return last(findmin(ss))
end
rand_rgb(n) = 2rand(CoN0, n) .- one(CoN0)
n = 100
n1 = n ÷ 2
factor = 2.7
for ncolor in 4:4, target in 1:ncolor
    colors = distinguishable_colors(ncolor, [RGB(1,1,1)], dropseed=true)
    img = fill(colors[target], n) .+ rand_rgb(n) ./ factor
    img[rand(1:n, n1)] .= fill(one(CoN0), n1) .+ rand_rgb(n1) ./ factor
    if classify(img, colors) ≠ target
        @show (ncolor, target)
    end
end
