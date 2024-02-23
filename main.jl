using Pluto, PlutoUI
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

