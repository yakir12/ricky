
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
w, h = (40, 35)
for (i, y) in enumerate(range(-arena_r - 5 - h, step=-h, length=4)), (j, x) in enumerate(range(-1.5w, step=w, length=3))
    poly!(ax, Rect(x, y, w, h), color=:transparent, strokewidth=2)
    text!(ax, x+w/2, y+h/2, text=string(LinearIndices((4, 3))[i, j]), align=(:center, :center))
end
save("toprint.pdf", fig)
