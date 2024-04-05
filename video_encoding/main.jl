using ColorTypes, ImageCore

w, h = (4056, 3040) # works

w2 = 64ceil(Int, w/64) # dimension adjustments to hardware restrictions
h2 = 32ceil(Int, h/32) # dimension adjustments to hardware restrictions
nb = Int(w2*h2*3/2) # total number of bytes per img
buff = Vector{UInt8}(undef, nb)
ystart = 1
yend = w2*h2
Y = view(reshape(view(buff, ystart:yend), w2, h2), 1:w2, h2:-1:1)
w4 = Int(w2/2)
h4 = Int(h2/2)
ustart = yend + 1
uend = ustart - 1 + w4*h4
u = view(reshape(view(buff, ustart:uend), w4, h4), 1:w4, h4:-1:1)
vstart = uend + 1
vend = vstart - 1 + w4*h4
v = view(reshape(view(buff, vstart:vend), w4, h4), 1:w4, h4:-1:1)


proc = open(`rpicam-vid -n --width $w --height $h --timeout 0 --codec yuv420 -o -`)
eof(proc)

read!(proc, buff)

to_img(bytes) = colorview(Gray, normedview(bytes))


using FileIO, ImageIO

save("Y.jpg", to_img(Y))
save("u.jpg", to_img(u))
save("v.jpg", to_img(v))

lkgflkdshlfdkhglfdshglkdgs


# img = RGB.(splat(YCbCr).(zip(rawview(N0f8.(channelview(restrict(Y)[2:end, 2:end]))), rawview(channelview(u)), rawview(channelview(v)))))
# save("img.jpg", img)


# using ImageDraw
using Statistics, LinearAlgebra
using ColorTypes, StaticArrays, Interpolations, CoordinateTransformations
using ImageCore, ImageTransformations
using AprilTags
import AngleBetweenVectors:angle

function get_all_indices()
    out = Dict{Int, Vector{SV}}()
    for id in 0:29
        img = getAprilTagImage(id, AprilTags.tag16h5)
        indices = findall(==(zero(eltype(img))), img)
        out[id] = SV.(Tuple.(indices))
    end
    return out
end

const SV = SVector{2, Float64}
@enum TagColor black=90 magenta=294 orange=20 green=120
const taghues = Dict(tc => reim(cis(deg2rad(Int(tc)))) for tc in instances(TagColor) if tc ≠ black)
const indices = get_all_indices()
const detector = AprilTagDetector(AprilTags.tag16h5)
detector.nThreads = 4

function good(tag)
    for i in 1:4
        p1, p2, p3, _ = circshift(tag.p, i)
        if !isapprox(angle(p1 .- p2, p3 .- p2), π/2; atol=0.1)
            return false
        end
    end
    return true
end


# drawables = [Polygon([Point(round.(Int, p)...) for p in tag.p]) for tag in tags]
# img = RGB.(Y)
# draw!(img, drawables, colorant"red")
# save("Y2.jpg", img)
# drawables = [Polygon([Point(round.(Int, p ./ 2)...) for p in tag.p]) for tag in tags]
# img = RGB.(u)
# draw!(img, drawables, colorant"red")
# save("u2.jpg", img)
# img = RGB.(v)
# draw!(img, drawables, colorant"red")
# save("v2.jpg", img)



rawchannel = rawview ∘ channelview
push1(x) = CoordinateTransformations.push(x, 1)
function get_colors(tag, yitp, uitp, vitp)
    s = 3.5
    scale = inv(SDiagonal(s, s, 1))
    M = LinearMap(SMatrix{3,3, Float64}(tag.H * scale))
    trans = Translation(-4.5, -4.5)
    itform = reverse ∘ PerspectiveMap() ∘ M ∘ push1 ∘ trans ∘ reverse
    itform2 = LinearMap(SDiagonal(1/2, 1/2)) ∘ itform
    ys = [yitp(itform(xy)...) for xy in indices[tag.id]]
    us = [uitp(itform2(xy)...) for xy in indices[tag.id]]
    vs = [vitp(itform2(xy)...) for xy in indices[tag.id]]
    V = YCbCr.(ys, us, vs)
end



# h = map(ts) do tag
#     colors = get_colors(tag, yitp, uitp, vitp)
#     hue.(colors)
# end
# h = vcat(h...)
# groups = repeat(1:4, inner = 28)
# violin(groups, h)


# map(ts) do tag
#     cs = get_colors(tag, yitp, uitp, vitp)
#     v = mean(cis ∘ deg2rad ∘ hue ∘ HSI, cs)
#     μ = normalize_hue(rad2deg(angle(v)))
#     σ = 1 - norm(v)
#     (; μ, σ)
# end



function classify(tag, yitp, uitp, vitp)
    cs = get_colors(tag, yitp, uitp, vitp)
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
    return (tag.id, tagcolor)
end

function get_tags(Y, u, v)
    tags = detector(Y)
    filter!(good, tags)
    yitp = interpolate(rawchannel(Y), BSpline(Linear()))
    uitp = interpolate(rawchannel(u), BSpline(Linear()))
    vitp = interpolate(rawchannel(v), BSpline(Linear()))
    ids = [classify(tag, yitp, uitp, vitp) for tag in tags]
    xy = [tag.c for tag in tags]
    return (ids, xy)
end

using FileIO, ImageIO
Y = load("/home/yakir/Y.jpg")
u = load("/home/yakir/u.jpg")
v = load("/home/yakir/v.jpg")

ids, xy = get_tags(Y, u, v)

img = RGB.(YCbCr.(rawchannel(Y), rawchannel(imresize(u, size(Y))), rawchannel(imresize(v, size(Y)))))

using GLMakie
image(img, axis=(;aspect=DataAspect()))
text!(reverse.(SV.(xy)); text=string.(first.(ids)), align=(:center, :center), color=:white)
# text!(reverse.(SV.(xy)); text=string.(last.(ids)), align=(:center, :center), color=:white)
# text!(reverse.(SV.(xy)); text=splat(string).(ids), align=(:center, :center), color=:white)


save("img.jpg", img)






    id = 8
    ts = filter(t -> t.id == id, tags)
    tc = map(ts) do tag
        classify(tag, yitp, uitp, vitp)
    end

    # orange:
    #  (μ = 320.8177396269681, σ = 0.008089467086969004)
    #  (μ = 241.90841887729914, σ = 0.37266097784759356)
    #  (μ = 359.81833754982864, σ = 0.009305506172743616)
    #  (μ = 159.90314426169, σ = 0.026504322669071434)
    0, 160, 320
    # RGB
    #  (μ = 131.2537263028628, σ = 0.029391633065562695)
    #  (μ = 236.2846606502772, σ = 0.2854565820002991)
    #  (μ = 238.43558346956593, σ = 0.005875862753584982)
    #  (μ = 353.8107525736472, σ = 0.0042446247226274325)
    0, 120, 240


    HSI.(120:120:360, 1, 1)

    ncolor = 4
    colors = distinguishable_colors(ncolor, [RGB{N0f8}(1,1,1)], dropseed=true)
    round.(Int, hue.(HSI.(colors)))






























    function convex_quadrilateral_to_indices_Y(cql)
        c = reverse(mean(SV, cql))
        w = 24
        window = CartesianIndices((-w:w, -w:w))
        return window .+ CartesianIndex(round.(Int, c)...)
    end
    function convex_quadrilateral_to_indices_uv(cql)
        c = reverse(mean(SV, cql)) ./ 2
        w = 12
        window = CartesianIndices((-w:w, -w:w))
        return window .+ CartesianIndex(round.(Int, c)...)
    end
    # function uv_indices(Yi)
    #     (x, y) = Yi.indices
    #     CartesianIndices(((x.start÷2:x.stop÷2), (y.start÷2:y.stop÷2)))
    # end



    for id in 0:29

        id = 0
        ts = filter(t -> t.id == id, tags)

        for (i, tag) in enumerate(ts)
            # tag = ts[1]
            Yi = convex_quadrilateral_to_indices_Y(tag.p)
            uvi = convex_quadrilateral_to_indices_uv(tag.p)
            yuv = splat(YCbCr).(zip(rawview(N0f8.(channelview(restrict(Y[Yi])))), rawview(channelview(u[uvi])), rawview(channelview(v[uvi]))))
            drawable = Polygon([Point(round.(Int, p)...) for p in tag.p])
            img = RGB.(yuv)
            draw!(img, drawable, RGB{Float32}(colorant"red"))
            save("$(tag.id)-$i.jpg", img)
        end







        drawables4 = [Polygon([Point(round.(Int, p/2)...) for p in tag.p]) for tag in tags if good(tag.p)]

        img = RGB.(u)
        draw!(img, drawables4, colorant"red")
        save("u2.jpg", img)

        img = RGB.(v)
        draw!(img, drawables4, colorant"red")
        save("v2.jpg", img)


        SV(xy::Point) = SV(xy.y, xy.x)

        using Statistics

        w = 10
        window = CartesianIndices((-w:w, -w:w))
        function convex_quadrilateral_to_indices(cql)
            c = mean(SV, cql)
            return window .+ CartesianIndex(round.(Int, c)...)
        end
        function uv_indices(Yi)
            (x, y) = Yi.indices
            CartesianIndices(((x.start÷2:x.stop÷2), (y.start÷2:y.stop÷2)))
        end

        rect = drawables[2]
        Yi = convex_quadrilateral_to_indices(rect.vertices)
        uvi = uv_indices(Yi)

        img = RGB.(Y)
        draw!(img, rect, colorant"red")
        save("img.jpg", img)

        using ImageTransformations

        # img = colorview(YCbCr, restrict(Y[Yi]), Gray{Float32}.(u[uvi]), Gray{Float32}.(v[uvi]))

        # colorview(YCbCr, rawview(N0f8.(channelview(restrict(Y[Yi])))), rawview(channelview(u[uvi])), rawview(channelview(v[uvi])))

        img = splat(YCbCr).(zip(rawview(N0f8.(channelview(restrict(Y[Yi])))), rawview(channelview(u[uvi])), rawview(channelview(v[uvi]))))
        save("img.jpg", RGB{N0f8}.(img))

        xy = map([Polygon([Point(round.(Int, p)...) for p in tag.p]) for tag in tags if tag.id == 1]) do rect
            Yi = convex_quadrilateral_to_indices(rect.vertices)
            uvi = uv_indices(Yi)
            (; u = gray.(vec(u[uvi])), v = gray.(vec(v[uvi])))
            # img = splat(YCbCr).(zip(rawview(N0f8.(channelview(restrict(Y[Yi])))), rawview(channelview(u[uvi])), rawview(channelview(v[uvi]))))
            # vec(img)
        end

        using GLMakie

        fig = Figure()
        ax = Axis(fig[1, 1], xlabel="U", ylabel="V")
        scatter!(ax, xy[1].u, xy[1].v)
        scatter!(ax, xy[2].u, xy[2].v)
        scatter!(ax, xy[3].u, xy[3].v)
        scatter!(ax, xy[3].u, xy[3].v)

        function classify(v, colors)
            indices = partialsortperm(v, 1:50, by = x -> x.y)
            ss = zeros(length(colors))
            for (i, color) in enumerate(colors), j in indices
                ss[i] += colordiff(color, v[j])
            end
            @show ss
            return last(findmin(ss))
        end
        ncolor = 4
        colors = distinguishable_colors(ncolor, [YCbCr(RGB{N0f8}(1,1,1))], dropseed=true)
        classify(vec(img), colors)




        patches = Dict("black" => decompose(Point2f, Rect(2391, 1644, 136, 160)),
                       "green" => decompose(Point2f, Rect(2241, 1469, 131, 157)),
                       "magenta" => decompose(Point2f, Rect(2243, 1647, 131, 157)),
                       "orange" => decompose(Point2f, Rect(2391, 1466, 131, 158))
                      )


        w = 40
        # window = CartesianIndices((-w:w, -w:w))
        # Yi = convex_quadrilateral_to_indices(patch)
        # i = deepcopy(Y)
        # i[Yi] .= zero(i[1])
        # image(i)

        function norm01(x)
            x .-= minimum(x)
            x ./= maximum(x)
            x
        end
        xy = Dict()
        for (k, patch) in patches
            # k, patch = first(patches)
            Yi = convex_quadrilateral_to_indices(patch)
            uvi = uv_indices(Yi)
            img = splat(YCbCr).(zip(rawview(N0f8.(channelview(restrict(Y[Yi])))), rawview(channelview(u[uvi])), rawview(channelview(v[uvi]))))
            V = vec(img)
            hsi = normalize_hue.(HSI.(V))
            indices = partialsortperm(hsi, 1:100, by = x -> x.i / x.s)
            # img = RGB.(img)
            # img[indices] .= RGB{Float32}(1,0,0)
            # image(img)
            xy[k] = (; h = hue.(hsi[indices]), weights = AnalyticWeights([hsi[i].s for i in indices]))
            # scatter(getfield.(xy, :s), getfield.(xy, :i), axis=(xlabel="Saturation", ylabel="Intensity"))
            # hist(getfield.(xy, :s) ./ getfield.(xy, :i))
        end
        x = repeat(1:length(xy), inner=10)
        y = vcat([v.h for v in values(xy)]...)
        weights = vcat([v.weights for v in values(xy)]...)
        violin(x, y; weights, datalimits = extrema, axis=(;xticks=(1:length(xy), collect(keys(xy)))))

        fig = Figure()
        ax = Axis(fig[1, 1], xlabel="U", ylabel="V", aspect=DataAspect())
        for (k, v) in xy
            scatter!(ax, v.u, v.v, label=k, markersize=25)
        end
        # scatter!(ax, xy[1].u, xy[1].v, label="black", color=colors[1], marker='x', markersize=25)
        # scatter!(ax, xy[2].u, xy[2].v, label="green", color=colors[4], marker='o', markersize=25)
        # scatter!(ax, xy[3].u, xy[3].v, label="magenta", color=colors[2], marker='*', markersize=25)
        # scatter!(ax, xy[4].u, xy[4].v, label="orange", color=colors[3], marker='□', markersize=25)
        axislegend(ax)
