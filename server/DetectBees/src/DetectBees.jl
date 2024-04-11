module DetectBees

using Statistics, LinearAlgebra, Dates
using ColorTypes, StaticArrays, Interpolations, CoordinateTransformations
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

@enum TagColor black=90 magenta=294 orange=20 green=120
const taghues = Dict(tc => reim(cis(deg2rad(Int(tc)))) for tc in instances(TagColor) if tc ≠ black)
const indices = get_all_indices()
const rawchannel = rawview ∘ channelview
const half = LinearMap(SDiagonal(1/2, 1/2))

include("camera.jl")
include("detect.jl")

function main()
    cam = Camera()
    tags = Ref([(id = "", xy = zero(SV))])
    task = Threads.@spawn while true
        snap!(cam)
        @time tags[] = detect(cam)
    end
    return (
            () -> collect(cam.Y),
            () -> (datetime = now(), tags = tags[]),
            task
           )
end

end
