using Statistics
using Oxygen
using ImageCore, StaticArrays, ImageTransformations, JpegTurbo

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

frame!(smallerY, cam) = String(jpeg_encode(rawview(imresize!(smallerY, normedview(cam.Y))); transpose=true))

mode = 1
camera_mode = camera_modes[mode]

const cam = Camera(camera_mode)
sz = round.(Int, (camera_mode.w, camera_mode.h) ./ 8)
const smallerY = Matrix{N0f8}(undef, sz)
const msg = Ref(frame!(smallerY, cam))

fps = FPS(10)
task = Threads.@spawn while isopen(cam)
    snap!(cam)
    msg[] = frame!(smallerY, cam)
    tick!(fps)
    yield()
end

@get "/frame" function()
    msg[]
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

serve(access_log=nothing, host="0.0.0.0", port=8000)
