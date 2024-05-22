using ImageCore, ColorTypes, Sixel, ImageInTerminal, ImageTransformations
import REPL

include(joinpath(@__DIR__(), "../server/DetectBees/src/camera.jl"))

cam = Camera(slow)

function plot(io, img)
    sixel_encode(io, imresize(colorview(Gray, normedview(img))[300:400, 300:400], (300, 300)))
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

