using GLMakie 
using Dates, HTTP, JSON3, TOML, DataStructures
using Base.Threads

@enum TagColor black=90 red=0 green=120 blue=240
const ip = "http://192.168.15.165:8000" # through ethernet

function get_state()
    r = HTTP.request("GET", "$ip/bees")
    return JSON3.read(String(r.body))
end

function set_state!(cache)
    for (here, there) in zip(cache, get_state())
        append!(here[], there)
        notify(here)
    end
end

function main()

    colors = repeat([Symbol.(instances(TagColor))...], inner=30)
    cache = [Observable(Point2f[]) for _ in 1:120]
    fig = Figure()
    ax = Axis(fig[1,1], aspect=DataAspect(), limits=(0, 2000, 0, 2000))
    for (xy, color) in zip(cache, colors)
        lines!(ax, xy; color)
    end
    running = Ref(true)
    get_state() # flush
    state_task = @async while running[]
        set_state!(cache)
        yield()
    end

    display(fig)

    return running

end

# running[] = false
