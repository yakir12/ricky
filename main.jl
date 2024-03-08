using Unitful, DataStructures
import Unitful: mm, cm, m, °

distance = 1m
arena = 150cm#150cm # 80cm # 
tag = 3mm
bytes = 2#8
p = 4
fov = 2atand(arena/2/distance)°
resolution = bytes*fov*p/(2atand(tag/2distance)°)
resolution^2/10^6 # → 294 MB

lenses = OrderedDict("6mmm" => (w=63°, h=63°),
                     "12MP 8mm" => (w=57.12°, h=42.44°),
                     "5MP 25mm" => (w=14.7°, h=11.1°),)
cameras = OrderedDict("v2" => (resolution=(w=3280, h=2464), fov=OrderedDict("fixed" => (w=62.2°, h=48.8°))),
                      "v3" => (resolution=(w=4608, h=2592), fov=OrderedDict("fixed" => (w=66°, h=41°))),
                      "v3w" => (resolution=(w=4608, h=2592), fov=OrderedDict("fixed" => (w=102°, h=67°))),
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

distance = 1m
tag = 3mm
bytes = 6
p = 5
camera = cameras["hq"]
for (lens, fovwh) in camera.fov
    fov = fovwh.w
    resolution_I_have = camera.resolution.w
    resolution_I_need = round(Int, bytes*fov*p/(2atand(tag/2distance)°))
    width = round(typeof(1cm), 2distance * tan(fov/2))
    @show lens, resolution_I_have, resolution_I_need, width
end

lenses = OrderedDict("6mm Wide Angle" => [(w = 63°, h = 63°)],
                     "16mm Telephoto" => [(w = 44.6°, h = 33.6°), (w = 30°, h = 23.2°), (w = 24.7°, h = 18.6°), (w = 21.8°, h = 16.4°)],
                     "25mm Telephoto" => [(w = 20.2°, h = 15.1°), (w = 16.5°, h = 12.4°), (w = 14.5°, h = 10.5°)],
                     "35mm Telephoto" => [(w = 20.9°, h = 15.8°), (w = 14.4°, h = 10.8°), (w = 10.5°, h = 7.9°)],
                     "8-50mm Zoom"    => [(w = 45°, h = 45°), (w = 5.35°, h = 5.35°)])
camera = (resolution=(w=4056, h=3040), fov=lenses)

distance = 1m
tag = 3mm
bytes = 6
p = 5
for (lens, fovwhs) in camera.fov, fovwh in fovwhs
    fov = fovwh.w
    resolution = round(Int, bytes*fov*p/(2atand(tag/2distance)°))
    width = round(typeof(1cm), 2distance * tan(fov/2))
    @show lens, resolution, width
end
