# Bee detection
My goal was to make as much progress as possible into investigating how to best track >100 individual bees using Apriltags.

## What I've done
I determined that the ideal Apriltag family for our purposes is the `standard41h12` family as it is equally small as the legacy `36h11` but more reliable. Using this Apriltag family also means that there are (near) zero false detections. I managed to create an algorithm that detects up to 120 bees at a rate of 80 FPS, which means that the camera-speeds are not hindered by the detection whatsoever. All communications between the Raspberry Pi unit that detects the bees and the central computer that stores the detections will be via Ethernet (currently WiFi) and are therefore near instantaneous. This means that the central computer will be able to handle scores (indeed thousands) of RPI units at the same time. All this points to a highly scalable solution. In the current setup, an arena with a diameter of 1.5 meters and tags that are 4 mm wide, I would recommend about 40 RPI units. Further investigation might conclude that a smaller number of units would be sufficient, but currently, my recommendation for a reliable system is indeed 40 RPIs.

## What affects the required number of RPI units?
These are the main factors that determine the minimum number of RPI units we need to reliably detect and track the bees:

- The relative size of the tag to the arena
- The walking speeds of the bees dictate the required speed of the camera
- The Apriltag family (higher number of bits on the tag requires a higher lens magnification)
- The chosen camera mode, each mode has its own spatial and temporal resolutions
- The camera lens, ideally we'll chose a set-focus lens with 25 mm focal length 

For instance, with the RPI HQ sensor (diagonal) size of 7.8568 mm, the `standard41h12` Apriltag family, a 4 mm tag, an arena of 1.5 meters, and a 35 mm focal length lens, one RPI unit could survey a 21 cm × 21 cm area, which would mean that ~38 RPI units are needed to cover the whole arena. 

## What's left to do
It would be very useful to determine if we can make do with less than 40 RPI units. This will involve exploring how good/bad the detected trajectories are at different temporal and spatial camera resolutions and lenses. Once we have the ideal number of RPI units, we would need to finalize the exact communication routine between the RPI units and the central computer. Once that is tested and done, we can order a few of the units for further testing (we should make sure that everything works as intended before ordering the full number of units). Once that is tested and done we can order the rest of the units. The plan is to power the RPIs via PoE (Power over Ethernet) which is ideal because we use the fastest communication available (via Ethernet) and power the RPIs at the same time (less cables). There will be some form of real-time monitoring (a live plot of where the bees are or have been in the last `x` seconds), but the real asset will be a saved high definition trajectory per bee.

# Remaining steps for collecting data + time estimates
1. Investigate if and how a lower number of RPI units would be possible: 7 days
2. Determine the exact lens we should proceed with: 3 days
3. Develop a finished version of the communication loop between the RPI units and central computer: 10 days
4. Test it with real/fake bees: 5 days
5. Order one set of all the parts, build the setup: 5 days
6. Test it with real/fake bees: 5 days
7. Order all the multiple units, cables, PoE switch box, central computer (can be any computer), build and connect it: 15 days
8. Test it with real/fake bees: 5 days

I'll probably need 55 additional days to complete this, i.e. about 3 more months of full-time work.
