using Statistics
using OhMyThreads, AprilTags, StaticArrays, TiledIteration, DataStructures

const SV = SVector{2, Float64}
const SVI = SVector{2, Int}


struct Detector
    detectors::Channel{AprilTagDetector}
    function Detector(ndetectors::Int)
        detectors = Channel{AprilTagDetector}(ndetectors)
        foreach(1:ndetectors) do _
            put!(detectors, AprilTagDetector()) 
        end
        new(detectors)
    end
end

function (d::Detector)(img)
    one_detector = take!(d.detectors)
    try
        return one_detector(img)
    catch ex
        @warn ex
        return AprilTag[]
    finally
        put!(d.detectors, one_detector)
    end
end

const ntags = 200

detect!(tags, detector, img; ntasks=Threads.nthreads()) = tforeach(TileIterator(axes(img), (110, 111)); ntasks, scheduler=:greedy) do i
    _tags = detector(img[i...])
    c₀ = SV(reverse(minimum.(i)))
    fill!(tags, missing)
    for tag in _tags 
        if tag.id < ntags
            tags[tag.id + 1] = round.(Int, SV(tag.c) + c₀)
        end
    end
end

mutable struct FPS{N}
    i::Int
    times::MVector{N, UInt64}
    FPS{N}() where {N} = new(0, MVector{N, UInt64}(1:N))
end
FPS(N::Int) = FPS{N}()

function tick!(fps::FPS{N}) where N
    fps.i += 1
    fps.times[fps.i] = time_ns()
    if fps.i == N
        println(round(Int, 10^9/mean(diff(fps.times))))
        fps.i = 0
    end
end

include(joinpath(@__DIR__(), "../server/DetectBees/src/camera.jl"))


mode = 1
camera_mode = camera_modes[mode]

const cam = Camera(camera_mode)

const detector = Detector(2Threads.nthreads())
const fps = FPS(50)
const tags = Union{Missing, SVI}[missing for _ in 1:587]
tags = Vector{Union{Missing, SVI}}(undef, ntags)
task = Threads.@spawn while isopen(cam)
    snap!(cam)
    detect!(tags, detector, cam.Y)
    # tick!(fps)
    yield()
end

using Oxygen, ImageCore, ImageTransformations, JpegTurbo, ImageDraw
sz = round.(Int, (camera_mode.w, camera_mode.h) ./ 1)
const smallerY = Matrix{RGB{N0f8}}(undef, sz)
mydraw!(_, ::Missing) = nothing
function mydraw!(img, tag::SVI)
    x, y = tag
    draw!(img, CirclePointRadius(x, y, 20), colorant"red")
    return nothing
end
@get "/frame" function()
    img = map(RGB ∘ Gray, normedview(cam.Y))
    foreach(tag -> mydraw!(img, tag), deepcopy(tags))
    imresize!(smallerY, img) 
    String(jpeg_encode(smallerY; transpose=true))
end

const ui = """
<!DOCTYPE html><html>
<head>
<meta charset="utf-8" />
<title>Oxygen App</title>
</head>
<body>
<div>
<img id="frame">
</div>
<script>
frame = document.querySelector("#frame");

async function loadImage() {
res = await fetch("/frame");
imgData = await res.blob();
frame.src = URL.createObjectURL(imgData);
}

setInterval(() => {
loadImage();
}, 100);
</script>
</body>
</html>
"""

@get "/" function()
    return ui
end

serve(access_log=nothing, host="0.0.0.0", port=8000, async=true)
