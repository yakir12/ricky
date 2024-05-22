using ImageCore, ColorTypes, Sixel, ImageInTerminal

include(joinpath(@__DIR__(), "../server/DetectBees/src/camera.jl"))

cam = Camera(fastest)

task = Threads.@spawn while isopen(cam)
    snap!(cam)
    display(colorview(Gray, normedview(cam.Y))[500:600, 500:600])
end

