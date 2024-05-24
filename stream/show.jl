using Statistics, LinearAlgebra
using OhMyThreads, AprilTags, StaticArrays
using ImageCore, ColorTypes, Sixel, ImageInTerminal, ImageTransformations
using ImageDraw
import REPL

include("camera.jl")

const SVI = SVector{2, Int}

const min_radius::Int = 25
const widen_radius::Int = 5
const max_radius::Int = 50
const mode::CameraMode = slow


camera_mode = camera_modes[mode]
const sz::Tuple{Int, Int} = (camera_mode.width, camera_mode.height)

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
        put!(pool, AprilTagDetector(AprilTags.tagStandard41h12)) 
    end
    return pool
end

const POOL = get_pool(20)

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


sz2 = (400, 400sz[2] ÷ sz[1])
r1, c1 = sz .÷ 2 .- 50
c2 = c1 + 100sz[2] ÷ sz[1]
function plot(io, img, dims)
    rgb = RGB.(colorview(Gray, normedview(img)))
    for p in points
        draw!(rgb, CirclePointRadius(p[2], p[1], 5), colorant"red")
    end
    sixel_encode(io, imresize(rgb[r1:r1+100, c1:c2], sz2))
    sixel_encode(io, imresize(rgb, sz2))
    show(io, dims)
    out = read(io, String)
    REPL.Terminals.clear(terminal)
    println(out)
end

_cursor_hide(io::IO) = print(io, "\x1b[?25l")
_cursor_show(io::IO) = print(io, "\x1b[?25h")

terminal = REPL.Terminals.TTYTerminal("", stdin, stdout, stderr)
_cursor_hide(stdout)
io = IOContext(PipeBuffer(), :color=>true)


nbees = 120
bees = Bee.(0:nbees - 1)

d = 13*(4+1) - 1 - 2*2

cam = Camera(mode)
task1 = Threads.@spawn while isopen(cam)
    snap!(cam)
    tforeach(bees) do bee
        if isalive(bee)
            bee(cam.Y)
        end
    end
    points = [bee.center for bee in bees if isalive(bee)]
    points2 = [bee.center for bee in bees if bee.id ∈ (12, 117) && isalive(bee)]
    dims = if length(points2) == 2
        l = norm(only(diff(points2)))
        string(round.(sz .* d ./ l, digits=2))
    else
        "-"
    end
    plot(io, cam.Y, dims)
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



