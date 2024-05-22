using ImageCore, ColorTypes, Sixel, ImageInTerminal
import REPL

include(joinpath(@__DIR__(), "../server/DetectBees/src/camera.jl"))

cam = Camera(fastest)

function plot(io, img)
    display(io, collect(colorview(Gray, normedview(img)))[500:600, 500:600])
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

