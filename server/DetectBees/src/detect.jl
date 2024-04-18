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
    v = mean(cis ∘ deg2rad ∘ hue ∘ HSI, cs)
    μ = normalize_hue(rad2deg(angle(v)))
    σ = 1 - norm(v)
    tagcolor = if σ > 0.04
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

function detect!(cam::Camera, tags)
    task = Threads.@spawn cam.detector(collect(cam.Y))
    itp = (Y = splat(interpolate(rawchannel(cam.Y), BSpline(Linear()))),
           uv = splat(interpolate(SV.(rawchannel(cam.u), rawchannel(cam.v)), BSpline(Linear()))))
    _tags = fetch(task)
    for tag in _tags
        if good(tag.p)
            index = classify_tag(tag.id, tag.H, itp)
            push!(tags[index], SV(tag.c))
        end
    end
end


