module DetectBees

using Statistics, LinearAlgebra
using Dates#, DataStructures
using OhMyThreads, AprilTags, StaticArrays
import PaddedViews:PaddedView
import OffsetArrays:centered

export main

include("camera.jl")

const SVI = SVector{2, Int}

const widen_radius::Int = 5
const max_radius::Int = 100

const POOL = Ref{Channel{AprilTagDetector}}()


function __init__()
    ndetectors = 40
    POOL[] = Channel{AprilTagDetector}(ndetectors)
    foreach(1:ndetectors) do _
        put!(POOL[], AprilTagDetector(AprilTags.tagStandard41h12)) 
    end
end

function detect(img)
    detector = take!(POOL[])
    tags = detector(img)
    put!(POOL[], detector)
    return tags
end

mutable struct Bee
    id::Int
    center::SVI
    radius::Int
    min_radius::Int
    Bee(id::Int, min_radius) = new(id, SVI(1,1), max_radius, min_radius)
end

isalive(b::Bee) = b.radius < max_radius

function found!(bee, tag_c)
    c = SVI(reverse(round.(Int, tag_c)))
    bee.center += c .- bee.radius
    bee.radius = bee.min_radius
end

function get_cropped(bee, buff)
    img = centered(buff, Tuple(bee.center))
    return img[-bee.radius:bee.radius, -bee.radius:bee.radius]
end

id_center(b::Bee) = (b.id, b.center)

function (bee::Bee)(buff)
    cropped = get_cropped(bee, buff)
    tags = detect(cropped)
    for tag in tags
        if tag.id == bee.id
            found!(bee, tag.c)
            return id_center(bee)
        end
    end
    bee.radius += widen_radius
    return id_center(bee)
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

function main(mode::CameraMode; nbees = 120)
    chn = Channel{Tuple{DateTime, Vector{Tuple{Int, SVI}}}}(1000)
    cam = Camera(mode)
    mode, width, height, framerate, min_radius = camera_modes[mode]
    bees = Bee.(0:nbees - 1, min_radius)
    # fps = FPS(round(Int, framerate))
    task1 = Threads.@spawn while isopen(cam)
        snap!(cam)
        data = tmap(Tuple{Int, SVI}, filter(isalive, bees)) do bee
            bee(cam.Y)
        end
        pkg = (now(), data)
        put!(chn, pkg)
        # tick!(fps)
    end
    detector = AprilTagDetector(AprilTags.tagStandard41h12)
    task2 = Threads.@spawn while isopen(cam)
        tags = detector(collect(parent(cam.Y)))
        for tag in tags
            i = tag.id + 1
            if i ≤ nbees
                bee = bees[i]
                if !isalive(bee)
                    bee.center = SVI(reverse(round.(Int, tag.c)))
                    bee.radius = bee.min_radius
                end
            end
        end
    end
    return (() -> take!(chn), task1, task2)
end

end
