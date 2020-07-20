# ProMeshScripts
- `polygonal_mesh_from_txt` - creates 2d polygonal mesh from plain text files in ProMesh

## Parameters
- Documented inline

## Usage (GUI)
1. Make sure you create a new mesh in ProMesh GUI (upper left corner)
2. Copy and paste into ProMesh live script editor
3. Adjust parameters (OPTIONAL)
4. Execute

## Usage (ugshell)
Run the following command string:
`ugshell -ex polygonal_mesh_from_txt.lua -helpMe` to show usage:
`
Executing polygonal_mesh_from_txt script...

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
`

The file should be stored in a `.ugx` file on your disk with specified output name.
Parameters can be made available to the command line user by using the scripts
`ug_util.lua` provided in `ugbase/scripts`.

### Version
Scripts have been tested with ProMesh 4.3.17 and ugshell (commit f46bab4).
