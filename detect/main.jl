# using Colors, ColorVectorSpace
# using FixedPointNumbers
# const CoN0 = RGB{N0f8}
#
# function classify(v, colors)
#     indices = partialsortperm(v, 1:10, by = x -> Gray(x))
#     ss = zeros(length(colors))
#     for (i, color) in enumerate(colors), j in indices
#         ss[i] += colordiff(color, v[j])
#     end
#     return last(findmin(ss))
# end
# rand_rgb(n) = 2rand(CoN0, n) .- one(CoN0)
# n = 100
# n1 = n ÷ 2
# factor = 2.7
# for ncolor in 4:4, target in 1:ncolor
#     colors = distinguishable_colors(ncolor, [RGB(1,1,1)], dropseed=true)
#     img = fill(colors[target], n) .+ rand_rgb(n) ./ factor
#     img[rand(1:n, n1)] .= fill(one(CoN0), n1) .+ rand_rgb(n1) ./ factor
#     if classify(img, colors) ≠ target
#         @show (ncolor, target)
#     end
# end

using FreeTypeAbstraction, AprilTags, ImageDraw

const detector = AprilTagDetector(AprilTags.tag16h5)
detector.nThreads = 4
const face = findfont("dejavu")
const pixelsize = 30


function detect!(img)
    tags = detector(collect(img))
    for tag in tags
        if tag.decision_margin > 50
            x, y = round.(Int, reverse(tag.c))
            renderstring!(img, string(tag.id), face, pixelsize, x, y, halign=:hcenter, valign=:vcenter)
            draw!(img, Polygon([Point(round.(Int, p)...) for p in tag.p]))
        end
    end
end


using JpegTurbo, VideoIO, Oxygen

const cam = opencamera("/dev/video2")
# const img = Ref(read(cam))
const buff = read(cam)
const ui = """
<!DOCTYPE html><html>
  <head>
    <meta charset="utf-8" />
    <title>Oxygen App</title>
  </head>
  <body>
    <div>
        <img id="frame">
    </div>
  <script>
    frame = document.querySelector("#frame");

    async function loadImage() {
      res = await fetch("/frame");
      imgData = await res.blob();
      frame.src = URL.createObjectURL(imgData);
    }

    setInterval(() => {
        loadImage();
    }, 33);
  </script>
  </body>
</html>
"""

# fetch fresh frames from the webcam
# task = Threads.@spawn while isopen(cam)
#     read!(cam, buff)
#     detect!(buff)
#     yield()
# end

# define routes
@get "/" function()
    return ui
end

@get "/frame" function()
    read!(cam, buff)
    detect!(buff)
    return buff |> jpeg_encode |> String
end

# start Oxygen server, in blocking mode
serve(access_log=nothing)
close(cam)
