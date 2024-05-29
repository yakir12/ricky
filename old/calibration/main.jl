
# using StaticArrays, 
using LinearAlgebra
using CairoMakie

include("../../stream/camera.jl")


light_r = 40/2
arena_r = 149/2
feeder_r = 14/2
l = 18
to_feeder = arena_r - l - feeder_r
n = 4
heights = [i => round(2arena_r/i, digits=2) for i in reverse(4:20)]
@show heights

fig = Figure()
axs = [Axis(fig[Tuple(CartesianIndices((2,2))[j])...], aspect = DataAspect(), xlabel="X (cm)", ylabel="Y (cm)", title = string(mode)) for (j, mode) in enumerate(instances(CameraMode))]
for (j, mode) in enumerate(instances(CameraMode))
    camera_mode = camera_modes[mode]
    _w, _h = sort([camera_mode.width, camera_mode.height], rev=true)
    h2w = _w/_h
    ax = axs[j]
    poly!(ax, Circle(zero(Point2f), arena_r), color=:transparent, strokewidth=2)
    poly!(ax, Circle(zero(Point2f), feeder_r), color=:gray)
    for θ in 0:π/2:3π/2
        poly!(ax, Circle(to_feeder*Point2f(reverse(sincos(θ))...), feeder_r), color=:gray)
    end
    # poly!(ax, Circle(zero(Point2f), light_r), color=(:yellow, 0.2), strokewidth=0)
    h = 2arena_r/n
    w = h2w*h
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
    @show mode, i
    hidedecorations!(ax)
    hidespines!(ax)
end
linkaxes!(axs...)

save("toprint.pdf", fig)


# Pardon the work update:
#
# I've now managed to build an algorithm that tracks as many as 120 bees with almost no delay whatsoever. This means that the speeds we can get are those of the camera itself. These are 120, 50, 40, and 10 FPS. Each FPS comes with its own spatial resolution and aspect ratio. I've now tested this and it seems like for reliable tracking (disregarding the speed of the bee), we would need 102, 41, 38, and 12 Raspberry Pis for each of the FPS respectively... So! I'll now test speeds a bit, but my guess is that we'll need more than 10 frames per second for these beasts, and therefore we might require about 41 RPIs...
#
# fastest : h = 11.46, n = 13, 102
# fast: h = 16.56, n = 9, 41
# slow: h = 21.29, n = 7, 38
# slowest: h = 37.25, n = 4, 12
