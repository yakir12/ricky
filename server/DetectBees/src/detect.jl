struct Detector
    detectors::Channel{AprilTagDetector}
    function Detector(ndetectors::Int)
        detectors = Channel{AprilTagDetector}(ndetectors)
        foreach(1:ndetectors) do _
            put!(detectors, AprilTagDetector(tag16h5)) 
        end
        new(detectors)
    end
end
function (d::Detector)(img)
    one_detector = take!(d.detectors)
    tags = one_detector(img)
    put!(d.detectors, one_detector)
    return tags
end

function good(p)
    # TODO: determine actual tag size and area, filter on that as well
    for i in 1:4
        p1, p2, p3, _ = circshift(p, i)
        if !isapprox(angle(p1 .- p2, p3 .- p2), π/2; atol=0.05)
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
    hsi = HSI.(cs)
    v = mean(cis ∘ deg2rad ∘ hue, hsi)
    μ = normalize_hue(rad2deg(angle(v)))
    σ = 1 - norm(v)
    tagcolor = if σ > 0.04
        # H = map(x -> getfield(x, :h), hsi)
        # I = map(x -> getfield(x, :i), hsi)
        # S = map(x -> getfield(x, :s), hsi)
        # @show H, S, I
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
    return idcol2index(id, color)
end

# tag2points(tag::AprilTag, c₀::SV) = SVector{4, SV}(c₀ + SV(p) for p in tag.p)

detect!(tags, detector, img; ntasks=Threads.nthreads()) = tmapreduce(vcat, TileIterator(axes(img), (110, 111)); ntasks, scheduler=:greedy) do i
    _tags = detector(img[i...])
    c₀ = SV(reverse(minimum.(i)))
    for tag in _tags 
        if good(tag.p)
            push!(tags[tag.id], SV(tag.c) + c₀)
        end
    end
end

