using Statistics
using OhMyThreads, AprilTags, StaticArrays, TiledIteration, DataStructures, ImageMorphology


const SV = SVector{2, Float64}
const SVI = SVector{2, Int}

struct Detector
    pool::Channel{AprilTagDetector}
    ntags::Int
    tile_c
    ntasks::Int
    function Detector(sz, ndetectors, ntags, ntasks)
        pool = Channel{AprilTagDetector}(ndetectors)
        foreach(1:ndetectors) do _
            put!(pool, AprilTagDetector()) 
        end
        tiles = TileIterator(Base.OneTo.(sz), (104, 152))
        c₀ = [SV(reverse(minimum.(i))) for i in tiles]
        tile_c = zip(tiles, c₀)
        return new(pool, ntags, tile_c, ntasks)
    end
end

function (d::Detector)(img)
    tforeach(d.tile_c; ntasks = d.ntasks, scheduler=:greedy) do (tile, c₀)
        detector = take!(d.pool)
        _tags = detector(img[tile...])
        put!(d.pool, detector)
        for tag in _tags 
            if tag.id < d.ntags
                # @show SV(tag.c) + c₀
            end
        end
    end
    return nothing
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

n = 100

for mode in 1:4
    camera_mode = camera_modes[mode]
    cam = Camera(camera_mode)
    ndetectors = 2Threads.nthreads()
    detector = Detector((camera_mode.w, camera_mode.h), ndetectors, 200, Threads.nthreads())
    t = @elapsed for i in 1:n
        snap!(cam)
        detector(cam.Y)
        yield()
    end
    println(round(Int, n/t), " fps")
    close(cam)
    foreach(1:ndetectors) do _
        AprilTags.freeDetector!(take!(detector.pool))
    end
    close(detector.pool)
end

