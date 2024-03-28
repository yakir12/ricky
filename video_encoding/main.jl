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

Y = load("/home/yakir/Y.jpg")
u = load("/home/yakir/u.jpg")
v = load("/home/yakir/v.jpg")

using AprilTags
import AngleBetweenVectors:angle
using ImageDraw
using ColorTypes

function good(p)
    for i in 1:4
        p1, p2, p3, _ = circshift(p, i)
        if !isapprox(angle(p1 .- p2, p3 .- p2), π/2; atol=0.3)
            return false
        end
    end
    return true
end

detector = AprilTagDetector(AprilTags.tag16h5)
detector.nThreads = 4
tags = detector(Y)
drawables = [Polygon([Point(round.(Int, p)...) for p in tag.p]) for tag in tags if good(tag.p)]

img = RGB.(Y)
draw!(img, drawables, colorant"red")

save("Y2.jpg", img)

drawables4 = [Polygon([Point(round.(Int, p/2)...) for p in tag.p]) for tag in tags if good(tag.p)]

img = RGB.(u)
draw!(img, drawables4, colorant"red")
save("u2.jpg", img)

img = RGB.(v)
draw!(img, drawables4, colorant"red")
save("v2.jpg", img)

SV(xy::Point) = SV(xy.y, xy.x)

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

function yuv2rgb(Y, U, V)
    Y = Y - 16
    U = U - 128
    V = V - 128
    R = 1.164 * Y             + 1.596 * V
    G = 1.164 * Y - 0.392 * U - 0.813 * V
    B = 1.164 * Y + 2.017 * U
    RGB(R/255, G/255, B/255)
end

img = [yuv2rgb(255gray(y), Int(reinterpret(UInt8, u)), Int(reinterpret(UInt8, v))) for (y, u, v) in zip(restrict(Y[Yi]), u[uvi], v[uvi])]

using ImageTransformations

img = colorview(Luv, gray.(restrict(Y[Yi])), gray.(u[uvi]), gray.(v[uvi]))

save("img.jpg", RGB.(img))





using Colors, ColorVectorSpace
using FixedPointNumbers
const CoN0 = RGB{N0f8}

function classify(v, colors)
    indices = partialsortperm(v, 1:10, by = x -> Gray(x))
    ss = zeros(length(colors))
    for (i, color) in enumerate(colors), j in indices
        ss[i] += colordiff(color, v[j])
    end
    return last(findmin(ss))
end
colors = distinguishable_colors(ncolor, [RGB(1,1,1)], dropseed=true)

rand_rgb(n) = 2rand(CoN0, n) .- one(CoN0)
n = 100
n1 = n ÷ 2
factor = 2.7
for ncolor in 4:4, target in 1:ncolor
    colors = distinguishable_colors(ncolor, [RGB(1,1,1)], dropseed=true)
    img = fill(colors[target], n) .+ rand_rgb(n) ./ factor
    img[rand(1:n, n1)] .= fill(one(CoN0), n1) .+ rand_rgb(n1) ./ factor
    if classify(img, colors) ≠ target
        @show (ncolor, target)
    end
end

