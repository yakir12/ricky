using ImageCore, ColorTypes, Sixel

include(joinpath(@__DIR__(), "../server/DetectBees/src/camera.jl"))

cam = Camera(fastest)

task = Threads.@spawn while isopen(cam)
    snap!(cam)
    show(colorview(Gray, normedview(cam.Y)))
end

