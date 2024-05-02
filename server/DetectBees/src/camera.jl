const camera_modes = ((w = 990, h = 1332, fps = 120),
         (w = 2028, h = 1080, fps = 50),
         (w = 2028, h = 1520, fps = 40),
         (w = 4056, h = 3040, fps = 10))
const mode = camera_modes[3]

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
    function Camera()
        w, h, fps = mode
        proc = open(`rpicam-vid --denoise cdn_off -n --framerate $fps --width $w --height $h --timeout 0 --codec yuv420 -o -`)
        buff, Y, u, v = get_buffer_img(w, h)
        new(buff, Y, u, v, proc)
    end
end

Base.close(cam::Camera) = kill(cam.proc)
Base.isopen(cam::Camera) = isopen(cam.proc)

snap!(cam::Camera) = read!(cam.proc, cam.buff)
