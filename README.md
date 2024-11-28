# Palladium

A lightweight renderer in Metal for iOS.


## Features:
 - Mobile camera, dynamic FOV
 - Smooth 60fps
 - UV texturing
 - OBJ model loading and PNG texture format (max dimension: 8192 x 8192)
 - Multiple objects per scene, complete with rotation, scaling, and translation transforms
 - Flat lighting
 - Compute kernel post-processing effects: toggle-able blur, color inversion, and wireframe mode

## Usage
Palladium is used in a landscape orientation.
Use the buttons on the far left side of the screen to move the camera forward and backward, and strafe left to right. The buttons in the middle-left of the screen will take the camera up and down.
Pinch the screen to increase/decrease the camera's field of view.
The toggle switches on the right side of the screen may be used to enable/disable certain post-processing effects. The box blur and Gaussian blur are very subtle. Use wireframe mode and focus on the edges of geometry to notice the difference.
Disabling texturing uses vertex color rather than texture sampling to color each object. Some objects have vertex color built-in, while others do not.

## Further Work
This project is open to improvement. Some feature ideas might be:
- Forward shading using point/directional sources
- Tone mapping
- Mipmapping/dynamic texture loading
- Double-buffering (i.e. render the next frame while the current one is being displayed)
- Object culling
- Reflections
- Post-processing effects: ambient occlusion, anti-aliasing
- Particle generation

## Credit
Special thanks to [Emily Hao](mailto:e.hao@wustl.edu) and [Edward Jeong](mailto:e.j.jeong@wustl.edu) for their contributions to this project.


