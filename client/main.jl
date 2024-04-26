using Statistics, LinearAlgebra, Dates, HTTP
using StaticArrays, Interpolations
using ImageCore, ImageTransformations, ImageFiltering, ImageMorphology
import AprilTags: AprilTag, AprilTagDetector, getAprilTagImage, tag16h5
import AngleBetweenVectors:angle

const SV = SVector{2, Float64}
const camera_modes = ((w = 990, h = 1332, fps = 120),
                      (w = 2028, h = 1080, fps = 50),
                      (w = 2028, h = 1520, fps = 40),
                      (w = 4056, h = 3040, fps = 10))
const mode = camera_modes[1]
const sz = (mode.w, mode.h)


# include("detect.jl")

using FileIO
img = load("img.jpg")
itp = interpolate(img, BSpline(Linear()))
detector = AprilTagDetector(tag16h5)

function good(p)
    for i in 1:4
        p1, p2, p3, _ = circshift(p, i)
        if !isapprox(angle(p1 .- p2, p3 .- p2), π/2; atol=0.3)
            return false
        end
    end
    return true
end
function resize(box::CartesianIndices, ci)
    b = 10
    buff = CartesianIndex(b, b)
    m = max(ci[minimum(box)] - buff, CartesianIndex(1, 1))
    M = min(ci[maximum(box)] + buff, CartesianIndex(sz...))
    m:M
end
using BenchmarkTools
struct MyDetector
    ci::CartesianIndices{2, Tuple{StepRange{Int, Int}, StepRange{Int, Int}}}
    img2::Matrix{Float64}
    tf::BitMatrix
    kernel::ImageCore.OffsetMatrix{Float64, Matrix{Float64}}
    function MyDetector(step, sz)
        xs = StepRange(1, step, sz[1])
        ys = StepRange(1, step, sz[2])
        ci = CartesianIndices((xs, ys))
        sz2 = size(ci)
        img2 = zeros(sz2)
        tf = falses(sz2)
        σ = 7/step
        kernel = -Kernel.DoG(σ)
        return new(ci, img2, tf, kernel)
    end
end
function (a::MyDetector)(img, itp)
    for i in eachindex(a.img2)
        a.img2[i] = itp(a.ci[i])
    end
    imfilter!(a.img2, a.img2, a.kernel)
    for i in eachindex(a.tf)
        a.tf[i] = a.img2[i] > 0.01
    end
    labels = label_components(a.tf)
    boxes2 = component_boxes(labels)
    tags = SVector{4, SV}[]
    for box2 in boxes2[1:end]
        box = resize(box2, a.ci)
        c₀ = SV(reverse(Tuple(minimum(box))))
        i = img[box]
        for tag in detector(i)
            if good(tag.p)
                push!(tags, SVector{4, SV}([c₀ + SV(p) for p in tag.p]))
            end
        end
    end
    return tags
end
a = MyDetector(11, sz)
@btime $a($img,$itp);



using ImageDraw
rgb = RGB.(img)
alltags = detector(img)
for tag in alltags
    if good(tag.p)
        draw!(rgb, Polygon([Point(round.(Int, p)...) for p in tag.p]), colorant"blue")
    end
end
alltags = a(img, itp)
for tag in alltags
    draw!(rgb, Polygon([Point(round.(Int, p)...) for p in tag]), colorant"red")
end
save("tmp.jpg", rgb)

