--------------------------------------------------------------------------------
-- This script creates a 2d polygonal mesh from provided txt data             --
-- Usage: Copy and paste into ProMesh's live script editor and apply          --
--                                                                            --
-- Note: Make sure file path of the txt file points to a valid location       --
--                                                                            --
-- Author: Stephan Grein                                                      --
-- Date:   05-21-2020                                                         --
--------------------------------------------------------------------------------
print("Executing polygonal_mesh_from_txt script...")
print()

--------------------------------------------------------------------------------
--- Load CLI helpers if ug is available
--------------------------------------------------------------------------------
UG_AVAILABLE = os.getenv("UGROOT")
if UG_AVAILABLE ~= nil then ug_load_script("ug_util.lua") end

--------------------------------------------------------------------------------
--- helper functions                                                         ---
--------------------------------------------------------------------------------
-- file exists function
local function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

-- read lines from file function
local function lines_from(file)
  if not file_exists(file) then return {} end
  lines = {}
  for line in io.lines(file) do lines[#lines + 1] = line end
  return lines
end

-- general get param function for ProMesh and ugshell
function get_param(str, default)
  if UG_AVAILABLE then
    loadstring("param=" .. str)()
    return param
  else
  return default
  end
end

-- emulate scan directory function (one does not want to include additional dependencies)
local function scandir(directory)
  local function linux()
    local pathSep = package.config:sub(1,1) -- '/' for Linux/OSX and '\\' for Windows
    if string.find(pathSep, '/') then return true end
    return false
  end

  local tmpFile = os.tmpname()
  local cmd = linux() and 'find ' .. directory .. ' -iname ' .. '"*.txt"' .. ' > ' .. tmpFile
                      or 'dir "'..directory..'" /b /ad >' .. tmpFile
  os.execute(cmd)
  return lines_from(tmpFile)
end

--------------------------------------------------------------------------------
--- Clear mesh                                                               ---
--------------------------------------------------------------------------------
mesh = Mesh()
SelectAll(mesh)
EraseSelectedElements(mesh, true, true, true)

--------------------------------------------------------------------------------
--- files and parameters                                                     ---
--------------------------------------------------------------------------------

-- request help or not
local help = get_param('util.HasParamOption("-helpMe", false, "Usage")', false)

-- local input folder
local inputFolder = get_param('util.GetParam("-inputFolder", nil, "Input folder containing towers")', nil)

-- file name where grid will be stored
local outputFileName = get_param('util.GetParam("-outputFileName", nil, "File name to output UGX")', nil)

-- there are four boundaries: top, bottom, left, right
local numBoundaries = get_param('util.GetParamNumber("-numBoundaries", 4, "Number of boundaries")', 4)

-- join corners of rectangle to one of the four bondaries
local joinCorners = not get_param('util.HasParamOption("-joinCornersNot", "Join corners")', false)

--------------------------------------------------------------------------------
--- pre-refinement and smoothing parameters for tower                        ---
--------------------------------------------------------------------------------
-- number of smoothing steps
local numSmoothingSteps = get_param('util.GetParamNumber("numSmoothingSteps", 1, "Number of smoothing steps")', 1)

-- alpha
local smoothingAlpha = get_param('util.GetParamNumber("-smoothingAlpha", 0.1, "Alpha for smoothing")', 0.1)

-- pre refinements of single polygons / towers only
local numPreRefinements = get_param('util.GetParamNumber("-numPreRefinements", 2, "Number of tower refinements")', 2)

--------------------------------------------------------------------------------
-- coordinates                                                               ---
--------------------------------------------------------------------------------
-- rectangular coordinates
local v1 = {
  x = get_param('util.GetParamNumber("-v1x", 0, "Top left x")', 0),
  y = get_param('util.GetParamNumber("-v1y", -118.57, "Top left y")', -118.57)
} -- bottom left
local v2 = {
  x = get_param('util.GetParamNumber("-v2x", 122.9, "Top right x")', 122.9),
  y = get_param('util.GetParamNumber("-v2y", -118.57, "Top right y")', -118.57)
} -- bottom right
local v3 = {
  x = get_param('util.GetParamNumber("-v3x", 0, "Bottom left x")', 0),
  y = get_param('util.GetParamNumber("-v3y", 0, "Bottom left y")', 0)
} -- top left
local v4 = {
  x = get_param('util.GetParamNumber("-v4x", 122.9, "Bottom right x")', 122.9),
  y = get_param('util.GetParamNumber("-v4y", 0, "Bottom right y")', 0)
} -- top right

 -- fix 3rd coordinate to zero
local zCoordinate = get_param('util.GetParamNumber("-zCoordinate", 0, "Fixed z coordinate")', 0)

--------------------------------------------------------------------------------
--- refinement and triangulation settings                                    ---
--------------------------------------------------------------------------------
-- number of isotropic refinements of mesh, might be increased for many polygons
local numRefinements = get_param('util.GetParamNumber("-numRefinements", 2, "Number of volume refinements")', 2)
-- final minimum triangle angle in delaunay triangulation for tower 
local minAngleTower = get_param('util.GetParamNumber("-minAngleTower", 25, "Dihedral for towers")', 25)
-- final minimum triangle angle in delaunay triangulation for vol
local minAngleVol = get_param('util.GetParamNumber("-minAngleVol", 25, "Dihedral for volumes")', 25)
-- remove doubles threshold
local doublesThreshold = get_param('util.GetParamNumber("-doubleThreshold", 0.0001, "Double removal threshold")', 0.0001)
-- 2d polygons
local polygons = { }

if help then
  -- only if ugshell is available, help can be printed.
  if (UG_AVAILABLE) then util.PrintHelp() end
else
   --------------------------------------------------------------------------------
   --- parameter validation                                                     ---
   --------------------------------------------------------------------------------
   if not inputFolder then
      if (UG_AVAILABLE) then util.PrintHelp() end
      print("Please provide a valid input folder")
   end

  for k, v in pairs(scandir(inputFolder)) do
    str = 'param=get_param(\'util.GetParam(\"-tower' .. k .. "\"," .. "\"" .. v
             .. '", ' .. '"' .. "Tower # " .. k .. "\")', nil)"
    loadstring(str)()
    table.insert(polygons, param)
  end

   for index, file in pairs(polygons) do
     if not file then
        if (UG_AVAILABLE) then util.PrintHelp() end
          print("Please provide a valid tower file for tower #" .. index)
     end
   end

   if not outputFileName then 
       if (UG_AVAILABLE) then util.PrintHelp() end
          print("Please provide a valid output file name")
   end

   --------------------------------------------------------------------------------
   --- create tower(s)                                                          ---
   --------------------------------------------------------------------------------
   -- read lines from file (each line represents a 2d coordinate)
   local currentIndex = 0 -- current number of vertices created so far
   local subsetIndex = -1 -- current subset index
   local lastIndex = 0 -- index of last vertex
   for fileindex, file in pairs(polygons) do
     write("Creating 2d polygon # " .. fileindex .. "/" .. #polygons .. " from provided .txt file '" .. file .. "'...")
     local lines = lines_from(file)
     lastIndex = lastIndex + #lines -- current last vertex index needs to get updated each iteration
     subsetIndex = fileindex-1 -- subset index for this tower (subsets starts at index 0)

     -- read each component of all 2d coordinates (separated by whitespace) and create mesh vertices
     local vertices = {}
     for k, v in pairs(lines) do
      local coordinates = {}
       for coordinate in v:gmatch("%S+") do table.insert(coordinates, coordinate) end
       vertex = CreateVertex(mesh, MakeVec(coordinates[1], coordinates[2], zCoordinate), subsetIndex)
       table.insert(vertices, vertex)
     end

     -- create mesh edges
     ClearSelection(mesh)
     for index, _ in pairs(vertices) do
       if (index < #lines) then
         SelectVertexByIndex(mesh, index-1 + currentIndex)
         SelectVertexByIndex(mesh, index + currentIndex)
         CreateEdge(mesh, subsetIndex)
         ClearSelection(mesh)
       end
     end
     ClearSelection(mesh)
     SelectVertexByIndex(mesh, lastIndex-1) -- last vertex for current polygon
     SelectVertexByIndex(mesh, currentIndex) -- first vertex for current polygon
     CreateEdge(mesh, subsetIndex)
     currentIndex = currentIndex+#lines -- vertex indices
     ClearSelection(mesh)
     print(" done!")
   end

   --------------------------------------------------------------------------------
   --- create rectangle                                                         ---
   --------------------------------------------------------------------------------
   rectIndex=subsetIndex+1 -- subset index for rectangle (#towers + 1)
   CreateVertex(mesh, MakeVec(v1.x, v1.y, zCoordinate), rectIndex)
   CreateVertex(mesh, MakeVec(v2.x, v2.y, zCoordinate), rectIndex)
   CreateVertex(mesh, MakeVec(v3.x, v3.y, zCoordinate), rectIndex)
   CreateVertex(mesh, MakeVec(v4.x, v4.y, zCoordinate), rectIndex)
   ClearSelection(mesh)

   --------------------------------------------------------------------------------
   --- rectangle boundary                                                       ---
   --------------------------------------------------------------------------------
   SelectVertexByIndex(mesh, currentIndex)
   SelectVertexByIndex(mesh, currentIndex+1)
   CreateEdge(mesh, rectIndex+1)
   ClearSelection(mesh)
   SelectVertexByIndex(mesh, currentIndex)
   SelectVertexByIndex(mesh, currentIndex+2)
   CreateEdge(mesh, rectIndex+2)
   ClearSelection(mesh)
   SelectVertexByIndex(mesh, currentIndex+1)
   SelectVertexByIndex(mesh, currentIndex+3)
   CreateEdge(mesh, rectIndex+3)
   ClearSelection(mesh)
   SelectVertexByIndex(mesh, currentIndex+3)
   SelectVertexByIndex(mesh, currentIndex+2)
   CreateEdge(mesh, rectIndex+4)
   ClearSelection(mesh)

   --------------------------------------------------------------------------------
   --- pre-refine only towers, then apply Laplacian smoothing                   ---
   --------------------------------------------------------------------------------
   for fileindex, file in pairs(polygons) do
     SelectSubset(mesh, fileindex-1, true, true, true, false)
     for i=1, numPreRefinements do
        Refine(mesh)
     end
     LaplacianSmooth(mesh, smoothingAlpha, numSmoothingSteps)
     ClearSelection(mesh)
   end

   --------------------------------------------------------------------------------
   --- remove doubles and (isotropic) refinement                                ---
   --------------------------------------------------------------------------------
   SelectAll(mesh)
   RemoveDoubles(mesh, doublesThreshold)
   EraseEmptySubsets(mesh)
   for i=1, numRefinements do SelectAll(mesh) Refine(mesh) end

   --------------------------------------------------------------------------------
   --- triangulate subsetwise                                                   ---
   --------------------------------------------------------------------------------
   -- Note: This *might* be problematic if the minimum angle for triangulation is
   --       too high for the initial triangulation. Thus we first triangulate the
   --       mesh piecewise with a small minimum angle (5), then improve tringulation
   --       later with a final larger minimum angle (20 or 30 is suggested for now).
   --       Another option: Triangulating the whole mesh with a high angle (20 or 30)
   --       and use SeparateFacesBySelectedEdges to separate the face subsets, but
   --       SeparateFacesBySelectedEdges does not always yield a consistent result.
   --       The piecewise triangulation approach might make it necessary to refine
   --       the non-triangulated edge set before pw. triangulation to be successful!
   --       The corresponding parameter is numRefinements and can be set on the top.
   ClearSelection(mesh)
   for i, file in pairs(polygons) do
     SelectSubset(mesh, i-1, true, true, true, false)
     -- 4 boundaries and 1 corner subset = 5
     TriangleFill(mesh, true, minAngleTower, rectIndex+5+i)
     ClearSelection(mesh)
   end
   ClearSelection(mesh)
   SelectAll(mesh)
   TriangleFill(mesh, true, minAngleVol, rectIndex+5+#polygons+1)

   --------------------------------------------------------------------------------
   --- subset naming                                                            ---
   --------------------------------------------------------------------------------
   subsetOffset = 5+#polygons
   SetSubsetName(mesh, rectIndex+5+#polygons+1, "vol")
   for i, file in pairs(polygons) do
      SetSubsetName(mesh, i-1,  "Tower #" .. i .. " bnd")
      SetSubsetName(mesh, i+subsetOffset, "Tower #" .. i .. " vol")
   end
   SetSubsetName(mesh, #polygons+1, "bnd right")
   SetSubsetName(mesh, #polygons+2, "bnd bottom")
   SetSubsetName(mesh, #polygons+3, "bnd top")
   SetSubsetName(mesh, #polygons+4, "bnd left")
   SetSubsetName(mesh, #polygons, "corners")
   ClearSelection(mesh)

   --------------------------------------------------------------------------------
   --- join corners to separate boundary subsets                                ---
   --------------------------------------------------------------------------------
   if joinCorners then
     for i=1, numBoundaries-1 do
       SelectSubset(mesh, #polygons+i, true, true, true, false)
       CloseSelection(mesh)
       AssignSubset(mesh, #polygons+i)
       ClearSelection(mesh)
     end
   end

   --------------------------------------------------------------------------------
   --- clean up grid                                                            ---
   --------------------------------------------------------------------------------
   EraseEmptySubsets(mesh)
   AssignSubsetColors(mesh)
   SelectAll(mesh)
   RemoveDoubleFaces(mesh)
   ClearSelection(mesh)

   --------------------------------------------------------------------------------
   --- improve triangulation                                                    ---
   --------------------------------------------------------------------------------
   SelectSubset(mesh, subsetOffset+#polygons-1, true, true, true, false)
   Retriangulate(mesh, minAngleVol)
   ClearSelection(mesh)
   for i=subsetOffset, subsetOffset+#polygons-1 do
     SelectSubset(mesh, i-1, true, true, true, false)
     Retriangulate(mesh, minAngleTower)
     ClearSelection(mesh)
   end

   --------------------------------------------------------------------------------
   --- assign grid name                                                         ---
   --------------------------------------------------------------------------------
   write("Saving mesh to file '" .. outputFileName .. "'... ")
   SaveMesh(mesh, outputFileName)
   print("done!")
end
