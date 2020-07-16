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
`ugshell -ex polygonal_mesh_from_txt.lua`.

The file should be stored in a `.ugx` file on your disk with specified output name.
Parameters can be made available to the command line user by using the scripts
`ug_util.lua` provided in `ugbase/scripts`.

### Version
Scripts have been tested with ProMesh 4.3.17 and ugshell (commit f46bab4).
