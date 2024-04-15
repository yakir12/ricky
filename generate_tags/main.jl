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
const a4 = (595, 842)

tag_width = 3.5
border = 0.

tag_bytes = 8 # due to the family
w = tag_bytes + 2border
border_rect = Rect2(Point2(0), Point2(w))
bkg_rect = Rect2(origin(border_rect) + Point2(border), Point2(tag_bytes))
tag_offset = Point2(origin(bkg_rect)...)

ids = 0:29
# colors = distinguishable_colors(4, [RGB(1,1,1)], dropseed=true)
colors = [RGB(0,0,0),
          # RGB(1,0,0),
          # RGB(0,1,0),
          RGB(0,0,1)]
ncolors = length(colors)

pt_per_unit = tag_width*mm2pt/tag_bytes

ncolumns = 10

# (ncolumns*(w - border) + border, length(ids)*ncolors*(w - border) + border)

fig = Figure(size = a4 ./ pt_per_unit, figure_padding = 0);
# fig = Figure();
ax = Axis(fig[1, 1], aspect = DataAspect(), limits=(0, a4[1], 0, a4[2]))
for column in 1:ncolumns, (id_i, id) in enumerate(ids), (col_i, color) in enumerate(colors)
    y = LinearIndices(CartesianIndices((length(ids), ncolors)))[id_i, col_i]
    plot1tag!(ax, Point2((column - 1)*(w - border), y*(w - border)), id, color, border_rect, bkg_rect, tag_offset)
end
hidedecorations!(ax)
hidespines!(ax)
tightlimits!(ax)
save("tags.pdf", fig; pt_per_unit)

dsfsdfksajfgdsaj:w


actual_tag_width = tag_width + 2border
# by x
ncolumns, os0 = divrem(a4[2], actual_tag_width)
ncolumns = Int(ncolumns)
offset0 = Point2(os0/2, os0/2)*mm2pt

ncolumns = 5
offset0 = Point2(100, 100)

ratio = tag_width/tag_bytes*mm2pt
w = actual_tag_width*mm2pt
ids = 0:29

fig = Figure(size=a4, figure_padding = 0);
ax = Axis(fig[1, 1], aspect = DataAspect(), limits = (0, a4[1], 0, a4[2]))
for col in 1:ncolumns, (icolor, color) in enumerate(colors), (iid, id) in enumerate(ids)
    y = LinearIndices(CartesianIndices((ncolors, length(ids))))[icolor, iid]
    offset = offset0 + actual_tag_width * Point2(col - 1, y - 1) * mm2pt
    plot1tag!(ax, w, ratio, id, offset, color)
end
hidedecorations!(ax)
hidespines!(ax)
save("tags.pdf", fig; pt_per_unit=1)

#
# for (offset0, tag_width) in zip((Point2(150, 250), Point2(300, 500)), (3.5, 8)) # mm
#     ratio = tag_width/tag_bytes*mm2pt
#     w = tag_width*mm2pt
#     ids = 0:29
#     # offset0 = Point2(a4...) / 2 - Point2(5w, 6w)
#
#     # xticks = range(start=offset0[1], step=w, length=2*5 + 1)
#     # yticks = range(start=offset0[2], step=w, length=2*6 + 1)
#     # buff = 20
#     # vlines!(ax, xticks; ymin = (yticks[1] - buff)/a4[2], ymax = (yticks[end] + buff)/a4[2], color=:gray, linewidth=0.5)
#     # hlines!(ax, yticks; xmin = (xticks[1] - buff)/a4[1], xmax = (xticks[end] + buff)/a4[1], color=:gray, linewidth=0.5)
#     for (ij, color) in enumerate(colors), (xy, id) in enumerate(ids)
#         i, j = Tuple(CartesianIndices((2, 2))[ij])
#         x, y = Tuple(CartesianIndices((5, 6))[xy])
#         offset1 = Point2((i - 1)*5w, (j - 1)*6w)
#         offset2 = Point2((x - 1)*w, (y - 1)*w)
#         # offset3 = Point2((x - 1)*0.1w, (y - 1)*0.1w)
#         plot1tag!(ax, w, ratio, id, offset0 + offset1 + offset2, color)
#     end
#     hidedecorations!(ax)
#     hidespines!(ax)
#     save("tags.pdf", fig; pt_per_unit=1)
# end
#
#
