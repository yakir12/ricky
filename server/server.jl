using DetectBees

using ImageCore, ImageTransformations
using Oxygen

w, h, _ = DetectBees.whfps
sz = round.(Int, (w, h) ./ 8)
const buffer = Matrix{N0f8}(undef, sz)

get_Y, get_tags, task = main();

frame() = binary(collect(vec(rawview(imresize!(buffer, normedview(get_Y()))))))

@get "/frame" frame

@get "/bees" get_tags

# @post "/setup" function(req)
#     set_setup(json(req, Dict))
#     return "done"
# end

serve(access_log=nothing, host="0.0.0.0", port=8000)

