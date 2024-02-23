---
marp: true
theme: gaia
_class: lead
paginate: true
backgroundColor: #fff
backgroundImage: url('https://marp.app/assets/hero-background.svg')
---

![bg left:40% 80%](https://datasturgeon.com/assets/logoname.svg)

# **Tracking bees**

Project description on how to track bees using AprilTags.

---

# Background

About 100 bees are released into a circular arena with 5 food-wells. The light polarization of the environment is manipulated in order to investigate the characteristics of the bees' working and long-term navigational memory. 

---

![bg left:40% 80%](https://april.eecs.umich.edu/media/apriltag/tagformats_web.png)

# AprilTags

AprilTags is a popular form of fiducial tagging. It allows us to quickly detect the location and the orientation of all the tags in an image.

---

# Objectives

1. For each individual bee, register which well it visited (date & time, visit number, and visit duration).
2. Track each individual bee's trajectory in the arena (coordinates & time). 

---

# Challenges

1. The physical properties of the tag
2. The size-ratio between the arena & tag

---

## The tag

- As large as the bee can manage
- Stiff enough to hold its flat shape
- Dirt repellant in order to keep the tag's high contrast 

--- 

### Solution

- **Normal paper**: super easy to print but can crease and soak dirt
- **Stonepaper**: More complicated to print but is stiffer and repels dirt 

---

## The ratio

- The arena is 1.5 m wide
- The tags are 3 mm wide

Implications: Minimum camera resolution is a wapping **300 MP** image!!!

Highest resolution camera on the market is the Basler boost with 65 MP for €6,299... 

---

### Calculating required resolution
```julia
distance = 1m
arena = 150cm
tag = 3mm
bytes = 8
p = 5
fov = 2atand(arena/2/distance)°
resolution = bytes*fov*p/(2atand(tag/2distance)°)

resolution^2/10^6 # → 294 MB
```

---

### Solution

We simply need to play around with the `arena`, `tag`, `bytes`, and `p` to discover what our options are:
- `arena`: 1.5 meters or, for instance, 80 cm to include only the wells
- `tag`: maybe a bigger tag is possible?
- `bytes`: are 30 or 35 individuals enough (instead of 587)?
- `p`: maybe a `p` of 3 is actually enough in our circumstances