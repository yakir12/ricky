@enum CameraMode fastest fast slow slowest

const camera_modes = Dict(
                          fastest => (mode = "1332:990:10:P", width = 1332, height = 990, framerate = 120.048),
                          fast => (mode = "2028:1080:12:P", width = 2028, height = 1080, framerate = 50.0275),
                          slow => (mode = "2028:1520:12:P", width = 2028, height = 1520, framerate = 40.0096),
                          slowest => (mode = "4056:3040:12:P", width = 4056, height = 3040, framerate = 10.0))

function get_buffer_img(w, h)
    w2 = 64ceil(Int, w/64) # dimension adjustments to hardware restrictions
    nb = Int(w2*h*3/2) # total number of bytes per img
    buff = Vector{UInt8}(undef, nb)
    ystart = 1
    yend = w2*h
    Y = view(reshape(view(buff, ystart:yend), w2, h), 1:w, h:-1:1)
    w4 = Int(w2/2)
    h4 = Int(h/2)
    ustart = yend + 1
    uend = ustart - 1 + w4*h4
    u = view(reshape(view(buff, ustart:uend), w4, h4), 1:Int(w/2), h4:-1:1)
    vstart = uend + 1
    vend = vstart - 1 + w4*h4
    v = view(reshape(view(buff, vstart:vend), w4, h4), 1:Int(w/2), h4:-1:1)
    return buff, Y, u, v
end

struct Camera
    buff::Vector{UInt8}
    Y::SubArray{UInt8, 2, Base.ReshapedArray{UInt8, 2, SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, Tuple{}}, Tuple{UnitRange{Int64}, StepRange{Int64, Int64}}, false}
    u::SubArray{UInt8, 2, Base.ReshapedArray{UInt8, 2, SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, Tuple{}}, Tuple{UnitRange{Int64}, StepRange{Int64, Int64}}, false}
    v::SubArray{UInt8, 2, Base.ReshapedArray{UInt8, 2, SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, Tuple{}}, Tuple{UnitRange{Int64}, StepRange{Int64, Int64}}, false}
    proc::Base.Process
    function Camera(mode::CameraMode)
        mode, width, height, framerate = camera_modes[mode]
        # proc = open(`rpicam-vid --denoise cdn_off -n --framerate $fps --width $w --height $h --timeout 0 --codec yuv420 -o -`) # 120 fps
        # proc = open(`rpicam-vid --denoise cdn_off -n --framerate $fps --mode 1332:990:10:P --timeout 0 --codec yuv420 -o -`) # only 30 fps
        # proc = open(`rpicam-vid --denoise cdn_off -n --framerate $fps --width $w --height $h --timeout 0 --codec yuv420 -o -`) # more than 120 fps
        # proc = open(`rpicam-vid --denoise cdn_off -n --framerate $fps --width $w --height $h --mode 1332:990:10:P --timeout 0 --codec yuv420 -o -`)
        proc = open(`rpicam-vid --denoise cdn_off -n --framerate $framerate --width $width --height $height --mode $mode --timeout 0 --codec yuv420 -o -`)
        buff, Y, u, v = get_buffer_img(width, height)
        new(buff, Y, u, v, proc)
    end
end

Base.close(cam::Camera) = kill(cam.proc)
Base.isopen(cam::Camera) = isopen(cam.proc)

snap!(cam::Camera) = read!(cam.proc, cam.buff)
