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
    return BezierPath(reduce(vcat, rectcommands(Rect((i - 1)*ratio, (j - 1)*ratio, ratio, ratio)) for i in axes(mat, 1) for j in axes(mat, 2) if mat[i, j]))
end

function plot1tag!(ax, id, offset, color)
    w = tag_width*mm2pt
    poly!(ax, Rect2(offset..., w, w), color = :white)
    path = get_path(id)
    poly!(ax, path + offset; color)
    # b1 = 0.
    # b2 = 2
    # for (s, x) in zip((-1,1), (0, w)), (t, y) in zip((-1,1), (0, w))
    #     lines!(ax, [offset + p for p in (Point2(x + s * b2, y), Point2(x + s * b1, y))], color = :black)
    #     lines!(ax, [offset + p for p in (Point2(x, y + t * b2), Point2(x, y + t * b1))], color = :black)
    # end
end


const mm2pt = 72/25.4 # multiply mm to get points
const tag_width = 3 # mm
const tag_bytes = 8 # due to the family
const ratio = tag_width/tag_bytes*mm2pt
const a4 = (595, 842)

fig = Figure(size=a4, figure_padding = 0);
ax = Axis(fig[1, 1], aspect = DataAspect())#, limits = (0, a4[1], 0, a4[2]))
for x in 1:6, y in 1:5
    id = LinearIndices
plot1tag!(ax, 1, Point2(0, 0), :red)
save("0.pdf", fig; pt_per_unit=1)



# poly!(ax, Rect2(buff, buff, (a4 .- 2buff)...), color = :gray90)
colors = distinguishable_colors(4, [RGB(1,1,1)], dropseed=true)
# colors = (RGB{N0f8}(1,0,0), RGB{N0f8}(0,1,0), RGB{N0f8}(0,0,1), colorant"white")
for (i, color) in enumerate(colors), (i, id) in enumerate(0:29)


for (i, color) in enumerate(colors), (path, (x, y)) in zip(paths, ((x, y) for x in 1:6, y in 1:5))
    poly!(ax, Rect2(buff + ratio*((tag_bytes + 2)*x), buff + ratio*((i - 1)*5*(tag_bytes + 2) + (tag_bytes + 2)*y), tag_width*mm2pt, tag_width*mm2pt), color = :white)
    poly!(ax, path + Point(buff, buff) + ratio*Point((tag_bytes + 2)*x - 1, (i - 1)*5*(tag_bytes + 2) + (tag_bytes + 2)*y - 1); color)
end
hidedecorations!(ax)
hidespines!(ax)

save("0.pdf", fig; pt_per_unit=1)
