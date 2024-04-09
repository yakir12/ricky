using FreeTypeAbstraction, Gtk4, GtkObservables, ImageCore, ImageDraw, Dates, HTTP, JSON3, TOML, JSONSchema

using Base.Threads

const Color = RGB{N0f8}

const camera = (4056, 3040)
const ratio = 8
const sz = camera .÷ ratio
const fps = 5
const ip = "http://192.168.135.111:8000" # through ethernet
const face = findfont("dejavu")
const pixelsize = 10

bytes2img(b::Vector{UInt8}) = Color.(colorview(Gray, normedview(reshape(b, sz))))

topoint(p) = ImageDraw.Point(Tuple(round.(Int, p)))

# draw_beetle!(img, tag) = draw!(img, CirclePointRadius(topoint(tag.xy ./ ratio), 1), Color(1, 0, 1))
draw_beetle!(img, tag) = renderstring!(img, tag.id, face, pixelsize, (round.(Int, reverse(tag.xy) ./ ratio))..., halign=:hcenter, valign=:vcenter, fcolor=Color(1,0,0))

function set_frame!(img)
    HTTP.open("GET", "$ip/frame") do io
        while !eof(io)
            img.val = bytes2img(read(io))
        end
    end
end

function set_image!(img, state)
    set_frame!(img)
    for tag in state[].tags
        draw_beetle!(img[], tag)
    end
    notify(img)
end

function get_state()
    r = HTTP.request("GET", "$ip/bees")
    return JSON3.read(String(r.body))
end

function connect_canvas!(c, state, running)
    img = Observable(bytes2img(rand(UInt8, prod(sz))))

    redraw = Gtk4.draw(c, img) do cnvs, img
        copy!(cnvs, img)
    end

    # maybe add camera 1080 to all the setups on loading
    frame_task = @spawn :default while running[]
        ta = @spawn :default set_image!(img, state)
        sleep(1/fps)
        fetch(ta)
    end
end

function main()
    running = Ref(true)

    win = GtkWindow("DancingQueen")
    # win[] = bx = GtkBox(:v)
    c = canvas(reverse(sz)...)
    push!(win, c)
    # widget(c).hexpand = widget(c).vexpand = true
    # f = GtkAspectFrame(reverse(sz)..., 1, false)
    # f[] = widget(c)
    # push!(bx, f)
    # push!(win, f)

    state = Ref(get_state())

    frame_task = connect_canvas!(c, state, running)

    state_task = @spawn :default while running[]
        state[] = get_state()
        yield()
    end

    show(win)
    @async Gtk4.GLib.glib_main()
    Gtk4.GLib.waitforsignal(win, :close_request)

    running[] = false

    return nothing
end
