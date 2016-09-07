# OctreeVisualizer

I had written a version of the Octree data structure for a different thing, but realized it wasn't working as it should, so I created this little visualizer to be able to view the Octree as elements get added to it, just to be able to see what was actually happening.
The visualization is done in a SceneKit scene, pretty simple stuff.
Being able to see what was happening helped me figure out a couple of bugs I had with my Octree implementation.

Swift 3, Xcode beta 6 - macOS app

![Screenshot](screenshot.png?raw=true "Screenshot")

(I realize iOS 10 includes an octree class as part of GamePlayKit, but I wanted to do it myself and its a pretty easy data structure to figure out)
