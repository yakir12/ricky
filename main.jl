using Unitful
import Unitful: mm, cm, m, °

distance = 1m
arena = 150cm#150cm # 80cm # 
tag = 3mm
bytes = 2#8
p = 4
fov = 2atand(arena/2/distance)°
resolution = bytes*fov*p/(2atand(tag/2distance)°)
resolution^2/10^6 # → 294 MB

lenses = OrderedDict("6mmm" => (w=63, h=63),
                     "12MP 8mm" => (w=57.12, h=42.44),
                     "5MP 25mm" => (w=14.7, h=11.1),)
cameras = OrderedDict("v2" => (resolution=(w=3280, h=2464), fov=OrderedDict("fixed" => (w=62.2, h=48.8))),
                      "v3" => (resolution=(w=4608, h=2592), fov=OrderedDict("fixed" => (w=66, h=41))),
                      "v3w" => (resolution=(w=4608, h=2592), fov=OrderedDict("fixed" => (w=102, h=67))),
                      "hq" => (resolution=(w=4056, h=3040), fov=lenses),
                      "gs" => (resolution=(w=1456, h=1088), fov=lenses))

tag = 3mm
bytes = 6
p = 5
for (name, camera) in cameras, (lens, fovwh) in camera.fov
    fov = fovwh.w
    resolution = camera.resolution.w
    distance = round(typeof(1cm), tag/2tand(bytes*fov*p/2resolution))
    width = round(typeof(1cm), 2distance*tand(fov/2))
    height = round(typeof(1cm), 2distance*tand(fovwh.h/2))
    @show name, lens, distance, width, height
end


