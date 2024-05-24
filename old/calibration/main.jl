
# using StaticArrays, 
using LinearAlgebra
using CairoMakie

include("../../stream/camera.jl")


light_r = 40/2
arena_r = 149/2
feeder_r = 14/2
l = 18
to_feeder = arena_r - l - feeder_r
n = 5
@show 2arena_r/n

fig = Figure()
axs = [Axis(fig[Tuple(CartesianIndices((2,2))[j])...], aspect = DataAspect(), xlabel="X (cm)", ylabel="Y (cm)", title = string(mode)) for (j, mode) in enumerate(instances(CameraMode))]
for (j, mode) in enumerate(instances(CameraMode))
    camera_mode = camera_modes[mode]
    _w, _h = sort([camera_mode.width, camera_mode.height], rev=true)
    ax = axs[j]
    poly!(ax, Circle(zero(Point2f), arena_r), color=:transparent, strokewidth=2)
    poly!(ax, Circle(zero(Point2f), feeder_r), color=:gray)
    for θ in 0:π/2:3π/2
        poly!(ax, Circle(to_feeder*Point2f(reverse(sincos(θ))...), feeder_r), color=:gray)
    end
    # poly!(ax, Circle(zero(Point2f), light_r), color=(:yellow, 0.2), strokewidth=0)
    w = 2arena_r/n
    h = _h/_w*w
    xs = collect(range(0, step = w, length = ceil(Int, 2arena_r/w)))
    xs .-= (xs[end] + w)/2
    ys = collect(range(0, step = h, length = ceil(Int, 2arena_r/h)))
    ys .-= (ys[end] + h)/2
    i = 0
    for x in xs, y in ys
        rect = Rect(x, y, w, h)
        if !all(p -> norm(p) > 0.9arena_r, decompose(Point2f, rect))
            i += 1
            poly!(ax, rect, color=:transparent, strokewidth=2)
            text!(ax, x+w/2, y+h/2, text=string(i), align=(:center, :center))
        end
    end
    hidedecorations!(ax)
    hidespines!(ax)
end
linkaxes!(axs...)

save("toprint.pdf", fig)
