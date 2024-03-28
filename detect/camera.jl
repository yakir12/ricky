
function get_buffer_img(w, h)
    w2 = 64ceil(Int, w/64) # dimension adjustments to hardware restrictions
    nb = Int(w2*h*3/2) # total number of bytes per img
    buff = Vector{UInt8}(undef, nb)
    frame = view(reshape(view(buff, 1:w2*h), w2, h), 1:w, h:-1:1)
    img = colorview(Gray, normedview(frame))
    return buff, img
end

struct Camera
    buff::Vector{UInt8}
    img
    proc::Base.Process
    function Camera()
        w, h = (4056, 3040) # works
        # w, h = (1332, 990) # doesn't works???
        # w, h = (2028, 1080) # works
        buff, img = get_buffer_img(w, h)
        proc = open(`rpicam-vid -n --width $w --height $h --timeout 0 --codec yuv420 -o -`)
        eof(proc)
        new(buff, img, proc)
    end
end

function Base.isopen(cam::Camera) 
    isopen(cam.proc)
end

function snap(cam)
    read!(cam.proc, cam.buff)
    return collect(cam.img)
end
