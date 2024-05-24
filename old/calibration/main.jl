
# using StaticArrays, 
using LinearAlgebra
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
w, h = (2arena_r/5, h/w*2arena_r/5)
xs = collect(range(0, step = w, length = ceil(Int, 2arena_r/w)))
xs .-= (xs[end] + w)/2
ys = collect(range(0, step = h, length = ceil(Int, 2arena_r/h)))
ys .-= (ys[end] + h)/2
i = 0
for x in xs, y in ys
    rect = Rect(x, y, w, h)
    if !all(p -> norm(p) > 0.9arena_r, decompose(Point2f, rect))
        global i
        i += 1
        poly!(ax, rect, color=:transparent, strokewidth=2)
        text!(ax, x+w/2, y+h/2, text=string(i), align=(:center, :center))
    end
end
save("toprint.pdf", fig)
