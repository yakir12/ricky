using Statistics
using OhMyThreads, AprilTags, StaticArrays, TiledIteration, DataStructures, ImageMorphology
using UnicodePlots
import REPL

const SVI = SVector{2, Int}

const min_radius::Int = 25
const widen_radius::Int = 5
const max_radius::Int = 50

include(joinpath(@__DIR__(), "../server/DetectBees/src/camera.jl"))
camera_mode = camera_modes[2]
const sz::Tuple{Int, Int} = (camera_mode.w, camera_mode.h)

function borrow(f::Function, c::Channel)
    v = take!(c)
    try
        return f(v)
    finally
        put!(c, v)
    end
end

function get_pool(ndetectors)
    pool = Channel{AprilTagDetector}(ndetectors)
    foreach(1:ndetectors) do _
        put!(pool, AprilTagDetector()) 
    end
    return pool
end

const POOL = get_pool(10)

mutable struct Bee
    id::Int
    center::SVI
    radius::Int
    Bee(id::Int) = new(id, sz .÷ 2, max_radius)
end

function indices(b::Bee) 
    r1, c1 = max.(1, b.center .- b.radius)
    r2, c2 = min.(sz, b.center .+ b.radius)
    return CartesianIndices((r1:r2, c1:c2))
end

isalive(b::Bee) = b.radius < max_radius

function found!(bee, tag_c, mi)
    c0 = SVI(reverse(round.(Int, tag_c)))
    bee.center = c0 .+ Tuple(mi)
    bee.radius = min_radius
end

function (bee::Bee)(buff)
    i = indices(bee)
    cropped = buff[i]
    tags = borrow(POOL) do detector
        detector(cropped)
    end
    for tag in tags
        if tag.id == bee.id
            found!(bee, tag.c, minimum(i))
            return nothing
        end
    end
    bee.radius += widen_radius
    return nothing
end



nbees = 200
bees = Bee.(0:nbees - 1)



# function plot(io, xs, ys)
#     show(io, scatterplot(xs, ys; xlim=(0, camera_mode.w), ylim=(0, camera_mode.h)))
#     out = read(io, String)
#     REPL.Terminals.clear(terminal)
#     println(out)
# end
# _cursor_hide(io::IO) = print(io, "\x1b[?25l")
# _cursor_show(io::IO) = print(io, "\x1b[?25h")
#
# terminal = REPL.Terminals.TTYTerminal("", stdin, stdout, stderr)
#
# _cursor_hide(stdout)
# io = IOContext(PipeBuffer(), :color=>true)
# # p = Plot(; xlim=(0, camera_mode.w), ylim=(0, camera_mode.h))

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

fps = FPS(30)

cam = Camera(camera_mode)
task1 = Threads.@spawn while isopen(cam)
    snap!(cam)
    tforeach(bees) do bee
        if isalive(bee)
            bee(cam.Y)
        end
    end
    tick!(fps)
    # points = [bee.center for bee in bees if isalive(bee)]
    # plot(io, first.(points), last.(points))
end

task2 = Threads.@spawn while isopen(cam)
    tags = borrow(POOL) do detector
        detector(collect(cam.Y))
    end
    for tag in tags
        i = tag.id + 1
        if i ≤ nbees
            bee = bees[i]
            if !isalive(bee)
                found!(bee, tag.c, CartesianIndex(1, 1))
            end
        end
    end
end

# _cursor_show(stdout)










# function plot(io, p, xs, ys)
#     show(io, scatterplot!(p, xs, ys))
#     out = read(io, String)
#     REPL.Terminals.clear(terminal)
#     println(out)
# end
#
# include(joinpath(@__DIR__(), "../server/DetectBees/src/camera.jl"))
#
# n = 500
#
# _cursor_hide(io::IO) = print(io, "\x1b[?25l")
# _cursor_show(io::IO) = print(io, "\x1b[?25h")
#
# terminal = REPL.Terminals.TTYTerminal("", stdin, stdout, stderr)
#
# ts = zeros(4)
# for mode in 1:4
#     camera_mode = camera_modes[mode]
#     cam = Camera(camera_mode)
#     ndetectors = 2Threads.nthreads()
#     detector = Detector((camera_mode.w, camera_mode.h), ndetectors, 200, Threads.nthreads())
#     _cursor_hide(stdout)
#     io = IOContext(PipeBuffer(), :color=>true)
#     p = Plot(; xlim=(0, camera_mode.w), ylim=(0, camera_mode.h))
#     ts[mode] = @elapsed for i in 1:n
#         snap!(cam)
#         tags = detector(cam.Y)
#         plot(io, p, last.(tags), first.(tags))
#         yield()
#     end
#     _cursor_show(stdout)
#     close(cam)
#     foreach(1:ndetectors) do _
#         AprilTags.freeDetector!(take!(detector.pool))
#     end
#     close(detector.pool)
# end
#
# fps = round.(Int, n ./ts)
#
#
#
#
#
#
#
