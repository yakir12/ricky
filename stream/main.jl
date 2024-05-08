using Statistics
using OhMyThreads, AprilTags, StaticArrays, TiledIteration, DataStructures, ImageMorphology


const SV = SVector{2, Float64}
const SVI = SVector{2, Int}

struct Detector
    pool::Channel{AprilTagDetector}
    tags::Vector{CircularBuffer{SVI}}
    tile_c_i
    candidates::BitMatrix
    ntasks::Int
    function Detector(sz, ndetectors, ntags, npoints, ntasks)
        pool = Channel{AprilTagDetector}(ndetectors)
        tags =  [CircularBuffer{SVI}(npoints) for _ in 1:ntags]
        foreach(1:ndetectors) do _
            put!(pool, AprilTagDetector()) 
        end
        tiles = TileIterator(Base.OneTo.(sz), (507, 304))
        c₀ = [SV(reverse(minimum.(i))) for i in tiles]
        tile_c_i = zip(tiles, c₀, eachindex(tiles))
        ntiles = size(tiles)
        candidates = trues(ntiles)
        return new(pool, tags, tile_c_i, candidates)
    end
end

function (d::Detector)(img)
    todo = (tile_c_i for (tile_c_i, good) in zip(d.tile_c_i, d.candidates) if good)
    fill!(detector.candidates, false)
    tforeach(todo; ntasks = d.ntasks, scheduler=:greedy) do (tile, c₀, i)
        detector = take!(d.pool)
        _tags = detector(img[tile...])
        put!(d.pool, detector)
        if !isempty(_tags)
            d.candidates[i] = true
        end
        for tag in _tags 
            if tag.id < d.ntags
                push!(d.tags[tag.id + 1], round.(Int, SV(tag.c) + c₀))
            end
        end
    end
    dilate!(d.candidates)
    d.candidates[:, 1] .= true
    d.candidates[:, end] .= true
    d.candidates[1, :] .= true
    d.candidates[end, :] .= true
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

mode = 4
camera_mode = camera_modes[mode]

const cam = Camera(camera_mode)
const detector = Detector((camera_mode.w, camera_mode.h), 2Threads.nthreads(), 200, 1000, Threads.nthreads())

# const fps = FPS(50)
task = Threads.@spawn while isopen(cam)
    snap!(cam)
    detector(cam.Y)
    # tick!(fps)
    yield()
end

using Oxygen, ImageCore, ImageTransformations, JpegTurbo, ImageDraw
sz = round.(Int, (camera_mode.w, camera_mode.h) ./ 16)
const smallerY = Matrix{RGB{N0f8}}(undef, sz)
mydraw!(_, ::Missing) = nothing
function mydraw!(img, tag::SVI)
    x, y = tag
    draw!(img, CirclePointRadius(x, y, 40), colorant"red")
    return nothing
end
@get "/frame" function()
    rgb = map(RGB ∘ Gray, normedview(cam.Y))
    foreach(tag -> mydraw!(rgb, last(tag)), filter(!isempty, detector.tags))
    foreach(empty!, detector.tags) 
    imresize!(smallerY, rgb) 
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
