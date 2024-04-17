module DetectBees

using Statistics, LinearAlgebra, Dates
using ColorTypes, StaticArrays, Interpolations, CoordinateTransformations, DataStructures
using ImageCore, ImageTransformations
import AprilTags: AprilTagDetector, getAprilTagImage, tag16h5
import AngleBetweenVectors:angle

export main

const SV = SVector{2, Float64}

function get_all_indices()
    out = Dict{Int, Vector{SV}}()
    for id in 0:29
        img = getAprilTagImage(id, tag16h5)
        indices = findall(==(zero(eltype(img))), img)
        out[id] = SV.(Tuple.(indices))
    end
    return out
end

@enum TagColor black=90 red=0 green=120 blue=240

id2index(id::Int) = id + 1
color2index(tc::TagColor) = findfirst(==(tc), instances(TagColor))
idcol2index(id::Int, tc::TagColor) = LinearIndices((30, length(instances(TagColor))))[id2index(id), color2index(tc)]

# @enum TagColor black=90 magenta=294 orange=20 green=120
const taghues = Dict(tc => reim(cis(deg2rad(Int(tc)))) for tc in instances(TagColor) if tc ≠ black)
const indices = get_all_indices()
const rawchannel = rawview ∘ channelview
const half = LinearMap(SDiagonal(1/2, 1/2))

include("camera.jl")
include("detect.jl")

function collect_tags!(tags)
    res = collect.(values.(tags))
    @async foreach(empty!, tags)
    return res
end

function main()
    cam = Camera()
    tags = [CircularBuffer{SV}(1000) for _ in 1:30length(instances(TagColor))]
    task = Threads.@spawn while true
        snap!(cam)
        detect!(cam, tags)
    end
    return (
            () -> collect(cam.Y),
            () -> collect_tags!(tags),
            task
           )
end

end
