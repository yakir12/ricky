using ImageCore, HTTP, FileIO

const Color = RGB{N0f8}

const camera_modes = ((w = 990, h = 1332, fps = 120),
         (w = 2028, h = 1080, fps = 50),
         (w = 2028, h = 1520, fps = 40),
         (w = 4056, h = 3040, fps = 10))
const mode = camera_modes[1]

const sz = (mode.w, mode.h)
# const ip = "http://192.168.135.111:8000" # through ethernet
const ip = "http://192.168.15.165:8000" # through ethernet

bytes2img(b::Vector{UInt8}) = Color.(colorview(Gray, normedview(reshape(b, sz))))


function set_frame!(img)
    HTTP.open("GET", "$ip/frame") do io
        while !eof(io)
            img .= read(io)
        end
    end
end

img = rand(UInt8, prod(sz))

set_frame!(img)

save("img.jpg", bytes2img(img))

