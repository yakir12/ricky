# using GLMakie, AprilTags, GeometryBasics
using CairoMakie, AprilTags, GeometryBasics
using Colors, ColorTypes, FixedPointNumbers

# only works cause the apriltag family is 16h5, so 30 tags, s 5 times 6 rows and columns

function rectcommands(r)
    mi = minimum(r)
    ma = maximum(r)
    [MoveTo(mi), LineTo(ma[1], mi[2]), LineTo(ma), LineTo(mi[1], ma[2]), ClosePath()]
end

function get_path(id, ratio)
    tag = getAprilTagImage(id, AprilTags.tag16h5) # a 8×8 grayscale image of the tag
    mat = tag .== zero(tag[1])
    return BezierPath(reduce(vcat, rectcommands(Rect((i - 1)*ratio, (j - 1)*ratio, ratio, ratio)) for i in axes(mat, 1) for j in axes(mat, 2) if mat[i, j]))
end

function plot1tag!(ax, w, ratio, id, offset, color)
    poly!(ax, Rect2(offset..., w, w), color = :white)
    path = get_path(id, ratio)
    poly!(ax, path + offset; color)
    # poly!(ax, Rect2(0, 0, w, w) + offset; color=:transparent, strokecolor=:black, strokewidth=0.1)
end

const mm2pt = 72/25.4 # multiply mm to get points
const tag_bytes = 8 # due to the family
const a4 = (595, 842)

fig = Figure(size=a4, figure_padding = 0);
ax = Axis(fig[1, 1], aspect = DataAspect(), limits = (0, a4[1], 0, a4[2]))
for (offset0, tag_width) in zip((Point2(150, 250), Point2(300, 500)), (3.5, 8)) # mm
    ratio = tag_width/tag_bytes*mm2pt
    w = tag_width*mm2pt
    colors = distinguishable_colors(4, [RGB(1,1,1)], dropseed=true)
    ids = 0:29
    # offset0 = Point2(a4...) / 2 - Point2(5w, 6w)

    # xticks = range(start=offset0[1], step=w, length=2*5 + 1)
    # yticks = range(start=offset0[2], step=w, length=2*6 + 1)
    # buff = 20
    # vlines!(ax, xticks; ymin = (yticks[1] - buff)/a4[2], ymax = (yticks[end] + buff)/a4[2], color=:gray, linewidth=0.5)
    # hlines!(ax, yticks; xmin = (xticks[1] - buff)/a4[1], xmax = (xticks[end] + buff)/a4[1], color=:gray, linewidth=0.5)
    for (ij, color) in enumerate(colors), (xy, id) in enumerate(ids)
        i, j = Tuple(CartesianIndices((2, 2))[ij])
        x, y = Tuple(CartesianIndices((5, 6))[xy])
        offset1 = Point2((i - 1)*5w, (j - 1)*6w)
        offset2 = Point2((x - 1)*w, (y - 1)*w)
        # offset3 = Point2((x - 1)*0.1w, (y - 1)*0.1w)
        plot1tag!(ax, w, ratio, id, offset0 + offset1 + offset2, color)
    end
    hidedecorations!(ax)
    hidespines!(ax)
    save("tags.pdf", fig; pt_per_unit=1)
end
