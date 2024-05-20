using Statistics
using OhMyThreads, AprilTags, StaticArrays, TiledIteration, DataStructures, ImageMorphology
using UnicodePlots
import REPL

const SV = SVector{2, Float64}
const SVI = SVector{2, Int}

const min_radius::Int = 25
const widen_radius::Int = 5
const max_radius::Int = 50
const sz::Tuple{Int, Int} = (990, 1332)

struct Bee
    id::Int
    detector::AprilTagDetector
    rect::MVector{4, Int}
    Bee(id::Int) = new(id, AprilTagDetector(), MVector(1, 1, 2max_radius + 1, 2max_radius + 1))
end

radius(b::Bee) = (b.rect[3] - b.rect[1]) ÷ 2

center(b::Bee) = b.rect[1:2] .+ radius(b)

isalive(b::Bee) = radius(b) < max_radius

function found!(bee, tag_c, r1, c1)
    c0 = SVI(reverse(round.(Int, tag_c)))
    c = c0 + SVI(r1, c1)
    bee.rect[1:2] .= max.(1, c .- min_radius)
    bee.rect[3:4] .= min.(sz, c .+ min_radius)
end

function (bee::Bee)(buff)
    r1, c1, r2, c2 = bee.rect
    cropped = buff[r1:r2, c1:c2]
    tags = bee.detector(cropped)
    for tag in tags
        if tag.id == bee.id
            return found!(bee, tag.c, r1, c1)
        end
    end
    bee.rect[1:2] .= max.(1, bee.rect[1:2] .- widen_radius)
    bee.rect[3:4] .= min.(sz, bee.rect[3:4] .+ widen_radius)
end

function plot(io, p, xs, ys)
    show(io, scatterplot!(p, xs, ys))
    out = read(io, String)
    REPL.Terminals.clear(terminal)
    println(out)
end
_cursor_hide(io::IO) = print(io, "\x1b[?25l")
_cursor_show(io::IO) = print(io, "\x1b[?25h")

terminal = REPL.Terminals.TTYTerminal("", stdin, stdout, stderr)

    _cursor_hide(stdout)
    io = IOContext(PipeBuffer(), :color=>true)
    p = Plot(; xlim=(0, camera_mode.w), ylim=(0, camera_mode.h))


include(joinpath(@__DIR__(), "../server/DetectBees/src/camera.jl"))



nbees = 5
bees = Bee.(0:nbees - 1)

camera_mode = camera_modes[1]
cam = Camera(camera_mode)
@async while isopen(cam)
    snap!(cam)
    tforeach(bees) do bee
        if isalive(bee)
            bee(cam.Y)
            plot(io, p, center(bee)...)
        end
    end
end

detector = AprilTagDetector()
@async while isopen(cam)
    tags = detector(cam.Y)
    for tag in tags
        i = tag.id + 1
        if i ≤ nbees
            bee = bees[i]
            if !isalive(bee)
                found!(bee, tag.c, 1, 1)
            end
        end
    end
end

# _cursor_show(stdout)











# struct Detector
#     pool::Channel{AprilTagDetector}
#     ntags::Int
#     tile_c
#     ntasks::Int
#     function Detector(sz, ndetectors, ntags, ntasks)
#         pool = Channel{AprilTagDetector}(ndetectors)
#         foreach(1:ndetectors) do _
#             put!(pool, AprilTagDetector()) 
#         end
#         tiles = TileIterator(Base.OneTo.(sz), (104, 152))
#         c₀ = [SV(reverse(minimum.(i))) for i in tiles]
#         tile_c = zip(tiles, c₀)
#         return new(pool, ntags, tile_c, ntasks)
#     end
# end
#
# (d::Detector)(img) = tmapreduce(vcat, d.tile_c; ntasks = d.ntasks, scheduler=:greedy) do (tile, c₀)
#     detector = take!(d.pool)
#     tags = detector(img[tile...])
#     put!(d.pool, detector)
#     [SV(tag.c) + c₀ for tag in tags if tag.id < d.ntags]
# end
#
# mutable struct FPS{N}
#     i::Int
#     times::MVector{N, UInt64}
#     FPS{N}() where {N} = new(0, MVector{N, UInt64}(1:N))
# end
# FPS(N::Int) = FPS{N}()
#
# function tick!(fps::FPS{N}) where N
#     fps.i += 1
#     fps.times[fps.i] = time_ns()
#     if fps.i == N
#         println(round(Int, 10^9/mean(diff(fps.times))))
#         fps.i = 0
#     end
# end
#
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