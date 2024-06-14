module DetectBees

using Statistics, LinearAlgebra
using Dates
using OhMyThreads, AprilTags, StaticArrays
import PaddedViews:PaddedView
import OffsetArrays:centered

export main

const SVI = SVector{2, Int}

include("camera.jl")

const widen_radius::Int = 5
const max_radius::Int = 100

mutable struct Bee
    id::Int
    center::SVI
    radius::Int
    Bee(id::Int) = new(id, SVI(1,1), max_radius)
end

isalive(b::Bee) = b.radius < max_radius

function found!(bee, tag_c, min_radius)
    c = SVI(reverse(round.(Int, tag_c)))
    bee.center += c .- bee.radius
    bee.radius = min_radius
end

function get_cropped(bee, buff)
    img = centered(buff, Tuple(bee.center))
    return img[-bee.radius:bee.radius, -bee.radius:bee.radius]
end

id_center(b::Bee) = (b.id, b.center)

function detect_tags(img, pool)
    detector = take!(pool)
    try
        return detector(img)
    finally
        put!(pool, detector)
    end
end

function detect_bee!(bee, buff, pool, min_radius)
    cropped = get_cropped(bee, buff)
    tags = detect_tags(cropped, pool)
    for tag in tags
        if tag.id == bee.id
            found!(bee, tag.c, min_radius)
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

function get_pool(ndetectors)
    pool = Channel{AprilTagDetector}(ndetectors)
    foreach(1:ndetectors) do _
        put!(pool, AprilTagDetector(AprilTags.tagStandard41h12)) 
    end
    return pool
end

function get_data(store)
    take!(store)
end

function main(mode::CameraMode; nbees = 120)
    min_radius = min_radii[mode]
    store = Channel{Tuple{DateTime, Vector{Tuple{Int, SVI}}}}(1000)
    pool = get_pool(20)
    cam = Camera(mode)
    mode, width, height, framerate = camera_modes[mode]
    bees = Bee.(0:nbees - 1)

    fps = FPS(round(Int, framerate))

    task1 = Threads.@spawn while isopen(cam)
        snap!(cam)
        data = tmap(Tuple{Int, SVI}, filter(isalive, bees)) do bee
            detect_bee!(bee, cam.Y, pool, min_radius)
        end
        pkg = (now(), data)
        put!(store, pkg)
        tick!(fps)
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
                    bee.radius = min_radius
                end
            end
        end
        sleep(0.1)
    end
    # return (() -> take!(store), task1, task2)
    return (() -> get_data(store), task1, task2)
end

end
