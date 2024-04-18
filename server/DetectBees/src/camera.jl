function get_buffer_img(w, h)
    w2 = 64ceil(Int, w/64) # dimension adjustments to hardware restrictions
    h2 = 32ceil(Int, h/32) # dimension adjustments to hardware restrictions
    nb = Int(w2*h2*3/2) # total number of bytes per img
    buff = Vector{UInt8}(undef, nb)
    ystart = 1
    yend = w2*h2
    Y = view(reshape(view(buff, ystart:yend), w2, h2), 1:w2, h2:-1:1)
    w4 = Int(w2/2)
    h4 = Int(h2/2)
    ustart = yend + 1
    uend = ustart - 1 + w4*h4
    u = view(reshape(view(buff, ustart:uend), w4, h4), 1:w4, h4:-1:1)
    vstart = uend + 1
    vend = vstart - 1 + w4*h4
    v = view(reshape(view(buff, vstart:vend), w4, h4), 1:w4, h4:-1:1)
    return buff, Y, u, v
end

function set_detector!(detector, n=4)
    @assert Threads.nthreads() ≥ n
    detector.nThreads = n
    # detector.quad_decimate =  1.0
    # detector.quad_sigma = 0.0
    # detector.refine_edges = 1
    # detector.decode_sharpening = 0.25
    return detector
end

struct Camera
    buff::Vector{UInt8}
    Y::SubArray{UInt8, 2, Base.ReshapedArray{UInt8, 2, SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, Tuple{}}, Tuple{UnitRange{Int64}, StepRange{Int64, Int64}}, false}
    u::SubArray{UInt8, 2, Base.ReshapedArray{UInt8, 2, SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, Tuple{}}, Tuple{UnitRange{Int64}, StepRange{Int64, Int64}}, false}
    v::SubArray{UInt8, 2, Base.ReshapedArray{UInt8, 2, SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, Tuple{}}, Tuple{UnitRange{Int64}, StepRange{Int64, Int64}}, false}
    proc::Base.Process
    detector::AprilTagDetector
    function Camera()

        w, h, fps = (1332,990,120) # 18
        # w, h, fps = (2028,1080,50) # 13
        # w, h, fps = (2028,1520,40) # 10
        # w, h, fps = (4056,3040,10) # 1

        buff, Y, u, v = get_buffer_img(w, h)
        proc = open(`rpicam-vid --denoise cdn_off -n --framerate $fps --width $w --height $h --timeout 0 --codec yuv420 -o -`)
        eof(proc)
        Threads.@spawn while isopen(proc)
            read!(proc, buff)
            yield()
        end
        detector = AprilTagDetector(tag16h5)
        set_detector!(detector)
        new(buff, Y, u, v, proc, detector)
    end
end

function Base.close(cam::Camera) 
    kill(cam.proc)
    freeDetector!(cam.detector)
end

# snap!(cam::Camera) = read!(cam.proc, cam.buff)

