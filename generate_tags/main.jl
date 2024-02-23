using CairoMakie, AprilTags, GeometryBasics
using Colors, ColorTypes, FixedPointNumbers

# only works cause the apriltag family is 16h5, so 30 tags, s 5 times 6 rows and columns

function rectcommands(r)
    mi = minimum(r)
    ma = maximum(r)
    [MoveTo(mi), LineTo(ma[1], mi[2]), LineTo(ma), LineTo(mi[1], ma[2]), ClosePath()]
end

function get_path(id, r)
    tag = getAprilTagImage(id, AprilTags.tag16h5) # a 8×8 grayscale image of the tag
    mat = tag .== zero(tag[1])
    path = BezierPath(reduce(vcat,
                             rectcommands(Rect(i*r,j*r,r,r)) for i in axes(mat, 1) for j in axes(mat, 2) if mat[i, j]
                            ))
    return path
end

mm2pt = 72/25.4 # multiply mm to get points
tag_width = 3 # mm
tag_bytes = 8 # due to the family

ratio = tag_width/tag_bytes*mm2pt
paths = get_path.(0:29, ratio)

fig = Figure(size=(595, 842), figure_padding = 0)
ax = Axis(fig[1, 1], aspect = DataAspect(), limits = (0, 595, 0, 842))
# colors = distinguishable_colors(5, [RGB(0,0,0), RGB(1,1,1)], dropseed=false)[2:end]
colors = (RGB{N0f8}(1,0,0), RGB{N0f8}(0,1,0), RGB{N0f8}(0,0,1), colorant"white")
for (i, color) in enumerate(colors), (path, (x, y)) in zip(paths, ((x, y) for x in 1:6, y in 1:5))
    poly!(ax, Rect2(ratio*((tag_bytes + 2)*x), ratio*((i - 1)*5*(tag_bytes + 2) + (tag_bytes + 2)*y), tag_width*mm2pt, tag_width*mm2pt), color = color)
    poly!(ax, path + ratio*Point((tag_bytes + 2)*x - 1, (i - 1)*5*(tag_bytes + 2) + (tag_bytes + 2)*y - 1); color = :black)
end
hidedecorations!(ax)
hidespines!(ax)

save("0.pdf", fig; pt_per_unit=1)
