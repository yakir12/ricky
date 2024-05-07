# using GLMakie, AprilTags, GeometryBasics
using CairoMakie, AprilTags, GeometryBasics
using Colors, ColorTypes, FixedPointNumbers
using CoordinateTransformations, Rotations
using Distributions, LinearAlgebra


# only works cause the apriltag family is 16h5, so 30 tags, s 5 times 6 rows and columns

function rectcommands(r, rot)
    p1, p2, p4, p3 = rot.(decompose(Point2f, r))
    [MoveTo(p1), LineTo(p2), LineTo(p3), LineTo(p4), ClosePath()]
end

function get_path(id, θ)
    tag = getAprilTagImage(id, AprilTags.tag36h11)
    mat = tag .== zero(tag[1])
    rot = recenter(Angle2d(θ), Point2f(5, 5))
    return BezierPath(reduce(vcat, rectcommands(Rect((i - 1), (j - 1), 1, 1), rot) for i in axes(mat, 1) for j in axes(mat, 2) if mat[i, j]))
end

function plot1tag!(ax, offset, id, color, θ)
    rot = recenter(Angle2d(θ), Point2f(5, 5))
    bkgd = decompose(Point2f, Rect(0, 0, tag_bytes, tag_bytes))
    bkgd[3:4] .= bkgd[[4,3]]
    bkgd .= rot.(bkgd)
    poly!(ax, bkgd .+ offset, color = :white)
    path = get_path(id, θ)
    poly!(ax, path + offset; color)
end

const mm2pt = 72/25.4 # multiply mm to get points
# const a4 = (595, 842)

tag_width = 8

tag_bytes = 10 # due to the family
pt_per_unit = tag_width*mm2pt/tag_bytes


ids = 0:200
colors = [RGB(0,0,0)]
ncolors = length(colors)

const a4 = (210, 297)
fig_size = floor.(Int, a4 .* tag_bytes ./ tag_width)
fig = Figure(size = fig_size, figure_padding = 0);
ax = Axis(fig[1, 1], aspect = DataAspect(), limits=(0, fig_size[1], 0, fig_size[2]), backgroundcolor = :gray80)
d = MixtureModel([MvNormal([fig_size...] ./ 1.8, 6max(fig_size...)*I), MvNormal([fig_size...] ./ 3, 2min(fig_size...)*I)])
for _ in 1:100
    id = rand(ids)
    color = rand(colors)
    offset = Point2f(rand(d))
    θ = 0#rand()*2π
    plot1tag!(ax, offset, id, color, θ)
end
hidedecorations!(ax)
hidespines!(ax)
save("tags_$tag_width.pdf", fig; pt_per_unit)
