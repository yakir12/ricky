using GLMakie 
using Dates, HTTP, JSON3, TOML

using Base.Threads

const ip = "http://192.168.15.165:8000" # through ethernet

function get_state()
    r = HTTP.request("GET", "$ip/bees")
    return JSON3.read(String(r.body))
end

function set_state(xy)
    state = get_state()
    for tag in state.tags
        if haskey(xy, tag.id)
            xy[tag.id][] = Point2f(tag.xy)
            # push!(xy[tag.id][], Point2f(tag.xy))
        else
            @warn "missing key: $tag"
        end
    end
end

function main()

    xy = Dict("$id-$color" => Observable(Point2f(1,1)) for id in 0:29 for color in (:black, :red, :green, :blue))

    fig = Figure()
    ax = Axis(fig[1,1], aspect=DataAspect(), limits=(0, 5000, 0, 5000))
    for (k, v) in xy
        id, color = split(k, '-')
        scatter!(ax, v; color=Symbol(color))
    end

    state_task = @spawn :default while true
        set_state(xy)
        yield()
        # for (k, v) in xy
        #     notify(v)
        # end
    end

    display(fig)

end

