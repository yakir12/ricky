
# using StaticArrays, LinearAlgebra
using CairoMakie

light_r = 40/2
arena_r = 149/2
feeder_r = 14/2
h = 18
to_feeder = arena_r - h - feeder_r

fig = Figure()
ax = Axis(fig[1,1], aspect = DataAspect(), xlabel="X (cm)", ylabel="Y (cm)")
poly!(ax, Circle(zero(Point2f), arena_r), color=:transparent, strokewidth=2)
poly!(ax, Circle(zero(Point2f), feeder_r), color=:gray)
for θ in 0:π/2:3π/2
    poly!(ax, Circle(to_feeder*Point2f(reverse(sincos(θ))...), feeder_r), color=:gray)
end
# poly!(ax, Circle(zero(Point2f), light_r), color=(:yellow, 0.2), strokewidth=0)
w, h = (10.35, 13.92)
w, h = (32.07, 24.04)
xs = collect(range(0, step = w, length = ceil(Int, 2arena_r/w)))
xs .-= xs[end]/2
ys = collect(range(0, step = h, length = ceil(Int, 2arena_r/h)))
ys .-= ys[end]/2
for (i, x) in enumerate(xs), (j, y) in enumerate(ys)
    poly!(ax, Rect(x, y, w, h), color=:transparent, strokewidth=2)
    text!(ax, x+w/2, y+h/2, text=string(LinearIndices((length(xs), length(ys)))[i, j]), align=(:center, :center))
end
save("toprint.pdf", fig)
