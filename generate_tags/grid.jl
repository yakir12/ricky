# using GLMakie, AprilTags, GeometryBasics
using PolygonOps, CairoMakie, AprilTags, GeometryBasics
using Colors, ColorTypes, FixedPointNumbers
using CoordinateTransformations, Rotations
using Distributions, LinearAlgebra


# only works cause the apriltag family is 16h5, so 30 tags, s 5 times 6 rows and columns

function rectcommands(r)
    mi = minimum(r)
    ma = maximum(r)
    [MoveTo(mi), LineTo(ma[1], mi[2]), LineTo(ma), LineTo(mi[1], ma[2]), ClosePath()]
end

function get_path(id)
    tag = getAprilTagImage(id, AprilTags.tagStandard41h12, blackborder = false)
    mat = tag .== zero(tag[1])
    return BezierPath(reduce(vcat, rectcommands(Rect((i - 1), (j - 1), 1, 1)) for i in axes(mat, 1) for j in axes(mat, 2) if mat[i, j]))
end

function plot1tag!(ax, offset, id, border_rect, bkg_rect, tag_offset)
    # poly!(ax, border_rect + offset, color = :white)
    # poly!(ax, bkg_rect + offset, color = :white)
    path = get_path(id)
    poly!(ax, path + offset + tag_offset; color = :black)
end

const mm2pt = 72/25.4 # multiply mm to get points
# const a4 = (210, 297)
# const a4 = (595, 842)

tag_width = 4

tag_bytes = 9 # due to the family
pt_per_unit = tag_width*mm2pt/tag_bytes

border = 2

const a4 = (210, 297)
ntags = 120
ids = 0:ntags - 1
rows = round(Int, sqrt(ntags/(a4[1]/a4[2])))
cols = ceil(Int, ntags/rows)
indices = CartesianIndices((rows, cols))

block_size = (tag_bytes*cols + border*(cols + 1), tag_bytes*rows + border*(rows + 1))

w = tag_bytes + 2border
w1 = tag_bytes + border
border_rect = Rect2(Point2f(0), Point2f(w))
bkg_rect = Rect2(origin(border_rect) + Point2f(border), Point2f(tag_bytes))
tag_offset = Point2f(origin(bkg_rect)...)


fig_size = ceil.(Int, block_size)#(600, 800)
offset0 = Point2f(fig_size)/2 - Point2f(block_size)/2 .- w1
fig = Figure(size = fig_size, figure_padding = 0);
ax = Axis(fig[1, 1], aspect = DataAspect(), limits=(0, fig_size[1], 0, fig_size[2]))
for id in ids
    p = Point2f(reverse(Tuple(indices[id + 1])))
    offset = w1*p + offset0
    plot1tag!(ax, offset, id, border_rect, bkg_rect, tag_offset)
end
hidedecorations!(ax)
hidespines!(ax)
save("tags_$tag_width.pdf", fig; pt_per_unit)



