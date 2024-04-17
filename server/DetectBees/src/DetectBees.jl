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
# @enum TagColor black=90 magenta=294 orange=20 green=120
const taghues = Dict(tc => reim(cis(deg2rad(Int(tc)))) for tc in instances(TagColor) if tc ≠ black)
const indices = get_all_indices()
const rawchannel = rawview ∘ channelview
const half = LinearMap(SDiagonal(1/2, 1/2))

include("camera.jl")
include("detect.jl")

function collect_tags!(tags)
    # res = filter(!isempty ∘ last, tags)
    res = Dict(k => collect(v) for (k, v) in tags if !isempty(v))
    @async foreach(empty!, values(tags))
    return res
end

function main()
    cam = Camera()
    tags = Dict("$id-$color" => CircularBuffer{@NamedTuple{datetime::DateTime, xy::SV}}(1000) for id in 0:29 for color in instances(TagColor))
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
