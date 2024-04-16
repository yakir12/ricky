# using GLMakie, AprilTags, GeometryBasics
using CairoMakie, AprilTags, GeometryBasics
using Colors, ColorTypes, FixedPointNumbers

# only works cause the apriltag family is 16h5, so 30 tags, s 5 times 6 rows and columns

function rectcommands(r)
    mi = minimum(r)
    ma = maximum(r)
    [MoveTo(mi), LineTo(ma[1], mi[2]), LineTo(ma), LineTo(mi[1], ma[2]), ClosePath()]
end

function get_path(id)
    tag = getAprilTagImage(id, AprilTags.tag16h5) # a 8×8 grayscale image of the tag
    mat = tag .== zero(tag[1])
    return BezierPath(reduce(vcat, rectcommands(Rect((i - 1), (j - 1), 1, 1)) for i in axes(mat, 1) for j in axes(mat, 2) if mat[i, j]))
end

function plot1tag!(ax, offset, id, color, border_rect, bkg_rect, tag_offset)
    poly!(ax, border_rect + offset, color = :black)
    poly!(ax, bkg_rect + offset, color = :white)
    path = get_path(id)
    poly!(ax, path + offset + tag_offset; color)
end

const mm2pt = 72/25.4 # multiply mm to get points
# const a4 = (210, 297)
# const a4 = (595, 842)

tag_width = 4

tag_bytes = 8 # due to the family
pt_per_unit = tag_width*mm2pt/tag_bytes

border = 0.2
rows = 60
cols = 46

ids = 0:29
colors = [RGB(0,0,0),
          RGB(1,0,0),
          RGB(0,1,0),
          RGB(0,0,1)]
ncolors = length(colors)

block_size = (tag_bytes*cols + border*(cols + 1), tag_bytes*rows + border*(rows + 1))

w = tag_bytes + 2border
w1 = tag_bytes + border
border_rect = Rect2(Point2(0), Point2(w))
bkg_rect = Rect2(origin(border_rect) + Point2(border), Point2(tag_bytes))
tag_offset = Point2(origin(bkg_rect)...)

idcol = [(id, color) for id in ids, color in colors]
tags = Iterators.Stateful(Iterators.cycle(CartesianIndices((length(ids), ncolors))))

fig_size = ceil.(Int, block_size .+ 25)#(600, 800)
offset0 = Point2(fig_size)/2 - Point2(block_size)/2 .- w1
fig = Figure(size = fig_size, figure_padding = 0);
ax = Axis(fig[1, 1], aspect = DataAspect(), limits=(0, fig_size[1], 0, fig_size[2]))
for row in 1:cols, col in 1:rows
    id, color = idcol[first(tags)]
    offset = w1*Point2(row, col) + offset0
    plot1tag!(ax, offset, id, color, border_rect, bkg_rect, tag_offset)
end
hidedecorations!(ax)
hidespines!(ax)
save("tags.pdf", fig; pt_per_unit)
