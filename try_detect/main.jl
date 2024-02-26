using AprilTags

include("camera.jl")

function report(img)
    tags = detector(img)
    msg = isempty(tags) ? "nothing detected" : join((tag.id for tag in tags), ",")
    println(msg)
end

function switch!(current, next)
    current[] = switch(current[], next[])
    next[] = nothing
end

detector = AprilTagDetector(AprilTags.tag16h5)
detector.nThreads = 4

camera = Ref(Camera(cm480))

for i in 1:100
    report(snap!(camera[]))
end
