# ProMeshScripts
- `polygonal_mesh_from_txt` - creates 2d polygonal meshes from plain text files.

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/73579ffd7a804e72929752559b37a8e2)](https://app.codacy.com/gh/NeuroBox3D/ProMeshScripts?utm_source=github.com&utm_medium=referral&utm_content=NeuroBox3D/ProMeshScripts&utm_campaign=Badge_Grade_Dashboard)
 [![Linux/OSX](https://travis-ci.org/NeuroBox3D/ProMeshScripts.svg?branch=master)](https://travis-ci.org/NeuroBox3D/ProMeshScripts)
[![Windows](https://ci.appveyor.com/api/projects/status/6nwlqfyatdb7lc7n?svg=true)](https://ci.appveyor.com/project/stephanmg/promeshscripts)
 [![License: LGPL v3](https://img.shields.io/badge/License-LGPL%20v3-blue.svg)](https://www.gnu.org/licenses/lgpl-3.0)


Biofilm grid generation requires four 2d point coordinates specifying the bounding box of the biofilm as a rectangle. Additionally so called towers, 2d polygons, are specified by 2d point coordinates to define sub-populations or domains of bacteria.

## Build instructions
This will vary depending from where the script should be run from. 
- In the case the script is used within the ProMesh's GUI, i.e. in the live script editor, just copy and paste the script `polygonal_mesh_from_txt.lua` to this editor and adjust parameters as you need.
- In the case `ugshell` is used, one needs to enable an additional plugin, ProMesh, during the build process of ug4. To install the plugin use `ughub installPackage ProMesh` and activate it during the build process via `cmake -DProMesh=ON` in your `BUILD` folder, then execute `make`. 

More details on usage are provided below.

## Parameters
- Documented inline
- Invoke `ugshell -helpMe` to print parameters

## Usage (GUI)
1. Make sure you create a new mesh in ProMesh GUI (upper left corner)
2. Copy and paste into ProMesh live script editor
3. Adjust parameters (OPTIONAL)
4. Execute

## Usage (ugshell)
Run the following command string:
`ugshell -ex polygonal_mesh_from_txt.lua -helpMe` to show usage:

```Executing polygonal_mesh_from_txt script...
 (number) -doubleThreshold   = 0.0001 : Double removal threshold (default = 0.0001)
 
 [option] -helpMe            = true :  (default = false)
 
 (string) -inputFolder       = nil : Input folder containing towers (default = nil)
 
 [option] -joinCornersNot    = false : Join corners (default = false)
 
 (number) -minAngleTower     = 25 : Dihedral for towers (default = 25)
 
 (number) -minAngleVol       = 25 : Dihedral for volumes (default = 25)
 
 (number) -numBoundaries     = 4 : Number of boundaries (default = 4)
 
 (number) -numPreRefinements = 2 : Number of tower refinements (default = 2)
 
 (number) -numRefinements    = 2 : Number of volume refinements (default = 2)
 
 (number) -outproc           = 0 : Sets the output-proc to id. (default = 0)
 
 (string) -outputFileName    = nil : File name to output UGX (default = nil)
 
 (number) -smoothingAlpha    = 0.1 : Alpha for smoothing (default = 0.1)
 
 (number) -v1x               = 0 : Top left x (default = 0)
 
 (number) -v1y               = -118.57 : Top left y (default = -118.57)
 
 (number) -v2x               = 122.9 : Top right x (default = 122.9)
 
 (number) -v2y               = -118.57 : Top right y (default = -118.57)
 
 (number) -v3x               = 0 : Bottom left x (default = 0)
 
 (number) -v3y               = 0 : Bottom left y (default = 0)
 
 (number) -v4x               = 122.9 : Bottom right x (default = 122.9)
 
 (number) -v4y               = 0 : Bottom right y (default = 0)
 
 (number) -zCoordinate       = 0 : Fixed z coordinate (default = 0)
 
 (number) numSmoothingSteps  = 1 : Number of smoothing steps (default = 1)
```

Example (Will assume **all** tower files are in a certain *folder* and grid will be saved in *test.ugx*):
```
ugshell -ex polygonal_mesh_from_txt.lua -inputFolder path/to/tower/files.txt -outputFileName test.ugx
```
Note that the vertices of the rectangle can be specifeid via `-v1x,-v1y,-v2x,-v2y,-v3x,-v3y,-v4x,-v4y`.


The file should be stored in a `.ugx` file on your disk with specified output name.
Parameters can be made available to the command line user by using the scripts
`ug_util.lua` provided in `ugbase/scripts`.

### Version
Scripts have been tested with ProMesh 4.3.17 and ugshell (commit f46bab4).

