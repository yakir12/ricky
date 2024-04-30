using AprilTags, StaticArrays, OhMyThreads, TiledIteration
import AngleBetweenVectors:angle
import AprilTags:tag16h5

using BenchmarkTools

const SV = SVector{2, Float64}

ndetectors = 2Threads.nthreads()
const detectors = Channel{AprilTagDetector}(ndetectors)
foreach(1:ndetectors) do _
    put!(detectors, AprilTagDetector(tag16h5)) 
end

good(tag::AprilTag) = good(tag.p)
function good(p)
    for i in 1:4
        p1, p2, p3, _ = circshift(p, i)
        if !isapprox(angle(p1 .- p2, p3 .- p2), π/2; atol=0.3)
            return false
        end
    end
    return true
end
tag2points(tag::AprilTag, c₀::SV) = SVector{4, SV}(c₀ + SV(p) for p in tag.p)
get_tags(img; ntasks=Threads.nthreads()) = tmapreduce(vcat, TileIterator(axes(img), (110, 111)); ntasks, scheduler=:greedy) do i
    detector = take!(detectors)
    tags = detector(img[i...])
    put!(detectors, detector)
    c₀ = SV(reverse(minimum.(i)))
    [tag2points(tag, c₀) for tag in tags if good(tag)]
end

using FileIO, ColorTypes
img = Gray.(load("img.jpg"))

@show length(get_tags(img))

@btime get_tags($img);






using ImageDraw, Colors
rgb = RGB.(img)
detector = AprilTagDetector(tag16h5)
alltags = detector(img)
for tag in alltags
    if good(tag)
        draw!(rgb, Polygon([Point(round.(Int, p)...) for p in tag.p]), colorant"blue")
    end
end
alltags = get_tags(img)
for tag in alltags
    draw!(rgb, Polygon([Point(round.(Int, p)...) for p in tag]), colorant"red")
end
save("tmp.jpg", rgb)

