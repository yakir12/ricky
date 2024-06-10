@enum CameraMode fastest fast slow slowest

const camera_modes = Dict(
                          fastest => (mode = "1332:990:10:P", width = 990, height = 1332, framerate = 120.048, min_radius = 25),
                          fast => (mode = "2028:1080:12:P", width = 2028, height = 1080, framerate = 50.0275, min_radius = 50),
                          slow => (mode = "2028:1520:12:P", width = 2028, height = 1520, framerate = 40.0096, min_radius = 50),
                          slowest => (mode = "4056:3040:12:P", width = 4056, height = 3040, framerate = 10.0, min_radius = 100))

function get_buffer_img(w, h)
    w2 = 64ceil(Int, w/64) # dimension adjustments to hardware restrictions
    nb = Int(w2*h*3/2) # total number of bytes per img
    buff = Vector{UInt8}(undef, nb)
    Y = PaddedView(0x00, view(reshape(view(buff, 1:w2*h), w2, h), 1:w, h:-1:1), (1 - max_radius:w + max_radius, 1 - max_radius:h + max_radius))
    return buff, Y
end

struct Camera
    buff::Vector{UInt8}
    Y#::SubArray{UInt8, 2, Base.ReshapedArray{UInt8, 2, SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, Tuple{}}, Tuple{UnitRange{Int64}, StepRange{Int64, Int64}}, false}
    proc::Base.Process
    function Camera(mode::CameraMode)
        mode, width, height, framerate, _ = camera_modes[mode]
        proc = open(`rpicam-vid --denoise cdn_off -n --framerate $framerate --width $width --height $height --mode $mode --timeout 0 --codec yuv420 -o -`)
        buff, Y = get_buffer_img(width, height)
        new(buff, Y, proc)
    end
end

Base.close(cam::Camera) = kill(cam.proc)
Base.isopen(cam::Camera) = isopen(cam.proc)

snap!(cam::Camera) = read!(cam.proc, cam.buff)

