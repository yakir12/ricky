module DetectBees

using Statistics, LinearAlgebra
using ColorTypes, StaticArrays, Interpolations, CoordinateTransformations
using ImageCore, ImageTransformations
import AprilTags: AprilTagDetector, getAprilTagImage, tag16h5
import AngleBetweenVectors:angle

export get_tags

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
const detector = Ref{AprilTagDetector}()
const rawchannel = rawview ∘ channelview
const half = LinearMap(SDiagonal(1/2, 1/2))

function __init__()
    detector[] = AprilTagDetector(tag16h5)
    detector[].nThreads = 4
end

function good(p)
    # TODO: determine actual tag size and area, filter on that as well
    for i in 1:4
        p1, p2, p3, _ = circshift(p, i)
        if !isapprox(angle(p1 .- p2, p3 .- p2), π/2; atol=0.1)
            return false
        end
    end
    return true
end

push1(x) = CoordinateTransformations.push(x, 1)

function get_transform(H)
    s = 3.5
    scale = inv(SDiagonal(s, s, 1))
    M = LinearMap(SMatrix{3,3, Float64}(H * scale))
    trans = Translation(-4.5, -4.5)
    return reverse ∘ PerspectiveMap() ∘ M ∘ push1 ∘ trans ∘ reverse
end

function get_colors(id, H, itp)
    itform = get_transform(H)
    to_Y = itp.Y ∘ itform
    to_uv = itp.uv ∘ half ∘ itform
    to_ycbcr(xy) = YCbCr(to_Y(xy), to_uv(xy)...)
    return to_ycbcr.(indices[id])
end

function classify_color(cs)
    v = mean(cis ∘ deg2rad ∘ hue ∘ HSI, cs)
    μ = normalize_hue(rad2deg(angle(v)))
    σ = 1 - norm(v)
    tagcolor = if σ > 0.1
        black
    else
        vh = reim(v)
        _, tc = findmin(th -> angle(vh, th), taghues)
        tc
    end
    return tagcolor
end

function classify_tag(id, H, itp)
    cs = get_colors(id, H, itp)
    color = classify_color(cs)
    return "$id-$color"
end


function get_tags(Y, u, v)
    tags = detector[](Y)
    itp = (Y = splat(interpolate(rawchannel(Y), BSpline(Linear()))),
           uv = splat(interpolate(SV.(rawchannel(u), rawchannel(v)), BSpline(Linear()))))
    return [(id = classify_tag(tag.id, tag.H, itp), xy = tag.c) for tag in tags if good(tag.p)]
end

end
