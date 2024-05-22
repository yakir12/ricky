using ImageCore, ColorTypes, Sixel, ImageInTerminal
import REPL

include(joinpath(@__DIR__(), "../server/DetectBees/src/camera.jl"))

cam = Camera(fastest)

function plot(img)
    REPL.Terminals.clear(terminal)
    display(colorview(Gray, normedview(img))[300:600, 300:600])
end

terminal = REPL.Terminals.TTYTerminal("", stdin, stdout, stderr)

_cursor_hide(io::IO) = print(io, "\x1b[?25l")
_cursor_hide(stdout)

task = Threads.@spawn while isopen(cam)
    snap!(cam)
    plot(cam.Y)
end

