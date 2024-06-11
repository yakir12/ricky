using Dates, HTTP, JSON3, StaticArrays
using GLMakie 

# const ip = "http://192.168.251.165:8000" # through ethernet
const ip = "http://192.168.0.158:8000" # at home

const SVI = SVector{2, Int}
function get_state()
    r = HTTP.request("GET", "$ip/bees")
    return JSON3.read(String(r.body), Tuple{DateTime, Vector{Tuple{Int, SVI}}})
end

fig = Figure()
ax = Axis(fig[1,1], aspect=DataAspect(), limits = ((1,990),(1, 1332)))
xys = Observable(SVI[])
scatter!(ax, xys)
task = @async while isopen(fig.scene)
    t, frame = get_state()
    xys[] = last.(frame)
end



















for i in 1:100
    data = get_state()
    @show length(data)
end


const camera_modes = ((w = 990, h = 1332, fps = 120),
         (w = 2028, h = 1080, fps = 50),
         (w = 2028, h = 1520, fps = 40),
         (w = 4056, h = 3040, fps = 10))
const mode = camera_modes[1]


function set_state!(cache)
    for (here, there) in zip(cache, get_state())
        append!(here[], reverse.(there))
        notify(here)
    end
end

function main()

    # colors = repeat([Symbol.(instances(TagColor))...], inner=30)
    texts = repeat([string(i)[1] for i in instances(TagColor)], inner=30)
    cache = [Observable(Point2f[]) for _ in 1:120]
    fig = Figure()
    ax = Axis(fig[1,1], aspect=DataAspect(), limits=(0, mode.w, 0, mode.h))
    for (xy, txt) in zip(cache, texts)
        scatter!(ax, xy, marker=txt)
        # text!(ax, xy, text="a")#; text=txt)
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
