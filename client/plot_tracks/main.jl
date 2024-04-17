using GLMakie 
using Dates, HTTP, JSON3, TOML, DataStructures
using Base.Threads

const ip = "http://192.168.15.165:8000" # through ethernet

function get_state()
    r = HTTP.request("GET", "$ip/bees")
    return JSON3.read(String(r.body))
end

function set_state!(cache)
    state = get_state()
    for (k, v) in state, (; datetime, xy) in v
        cache[k][DateTime(datetime)] = Point2f(xy)
    end
end

function main()

    cache = Dict(Symbol("$id-$color") => SortedDict{DateTime, Point2f}() for id in 0:29 for color in (:black, :red, :green, :blue))
    fig = Figure()
    ax = Axis(fig[1,1], aspect=DataAspect(), limits=(0, 5000, 0, 5000))
    lns = map(collect(keys(cache))) do k
        ln = Observable(Point2f[])
        lines!(ax, ln)
        ln
    end
    for i in 1:1000
        set_state!(cache)
        for (i, (k, v)) in enumerate(cache)
            if !isempty(v)
                lns[i][] = collect(values(v))
            end
            # append!(lns[k][], collect(values(v)))
            # notify(lns[k])
        end
        yield()
    end


    lns = [Observable(Point2f[]) for k in keys(cache)]
    for (ln, 

    ln = Observable(Point2f[])
    lines!(ax, ln)

    for _ in 1:100
        set_state!(cache)
        ln[] = collect(values(first(values(filter(!isempty ∘ last, cache)))))
    end


    lns = Dict(k => Observable(Point2f[]) for k in keys(cache))
    for (k, ln) in lns
        _, color = split(String(k), '-')
        lines!(ax, ln; color=Symbol(color))
    end

    running = Ref(true)
    state_task = @spawn :default while running[]
        set_state!(cache)
        for (k, v) in cache
            lns[k][] = collect(values(v))
            # append!(lns[k][], collect(values(v)))
            # notify(lns[k])
        end
        sleep(0.1)
    end

    running[] = false

    display(fig)

end

