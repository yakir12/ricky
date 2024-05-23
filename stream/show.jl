using ImageCore, ColorTypes, Sixel, ImageInTerminal, ImageTransformations
import REPL

include(joinpath(@__DIR__(), "../server/DetectBees/src/camera.jl"))

mode = slow
cam = Camera(mode)
camera_mode = camera_modes[mode]
sz = (camera_mode.width, camera_mode.height)

sz2 = (400, 400sz[2] ÷ sz[1])
r1, c1 = sz .÷ 2 .- 50
c2 = c1 + 100sz[2] ÷ sz[1]
function plot(io, img)
    sixel_encode(io, imresize(colorview(Gray, normedview(img))[r1:r1+100, c1:c2], sz2))
    sixel_encode(io, imresize(colorview(Gray, normedview(img)), sz2))
    out = read(io, String)
    REPL.Terminals.clear(terminal)
    println(out)
end

_cursor_hide(io::IO) = print(io, "\x1b[?25l")
_cursor_show(io::IO) = print(io, "\x1b[?25h")

terminal = REPL.Terminals.TTYTerminal("", stdin, stdout, stderr)
_cursor_hide(stdout)
io = IOContext(PipeBuffer(), :color=>true)

task = Threads.@spawn while isopen(cam)
    snap!(cam)
    plot(io, cam.Y)
end
# _cursor_show(stdout)

