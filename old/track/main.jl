function send_frame()
    img = snap()
    tags = get_tags(img)
    body = Dict(tag.id => tag.coordinate for tag in tags)
    if !isempty(body)
        HTTP.post("$ip/frame"; body)
    end
end

Threads.@spawn while true
    send_frame()
    yield()
end
