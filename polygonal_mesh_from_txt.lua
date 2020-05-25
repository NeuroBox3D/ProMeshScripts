--------------------------------------------------------------------------------
-- This script creates a 2d polygonal mesh from provided txt data             --
-- Usage: Copy and paste into ProMesh's live script editor and apply          --
--                                                                            --
-- Note: Make sure file path of the txt file points to a valid location       --
--                                                                            --
-- Author: Stephan Grein                                                      --
-- Date:   05-21-2020                                                         --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- path to 2d polygon tower
local file = '/Users/stephan/test.txt'

-- rectangular coordinates
local v1 = {
  x = 50.5,
  y = -50
} -- bottom left
local v2 = {
  x =149.5,
  y = -50
} -- bottom right
local v3 = {
  x =50.5,
  y = 50
} -- top left
local v4 = {
  x =149.5,
  y = 50
} -- top right

-- number of isotropic refinements of whole edge mesh
local numRefinements = 2
-- minimum triangle angle in delaunay triangulation
local minAngle = 20

-- file exists function
function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

-- read lines from file function
function lines_from(file)
  if not file_exists(file) then return {} end
  lines = {}
  for line in io.lines(file) do lines[#lines + 1] = line end
  return lines
end

----------------------------------------------------
--- create tower
----------------------------------------------------
-- read lines from file (each line represents a 2d coordinate)
local lines = lines_from(file)
local lastIndex = #lines -- number of coordinates, line number used as vertex index
local subsetIndex = 0
local zCoordinate = 0 -- fix 3rd coordinate

-- read each component of all 2d coordinates (separated by whitespace) and create mesh vertices
local vertices = {}
for k, v in pairs(lines) do
  local coordinates = {}
  for coordinate in v:gmatch("%S+") do table.insert(coordinates, coordinate) end
  vertex = CreateVertex(mesh, MakeVec(coordinates[1], coordinates[2], zCoordinate), subsetIndex)
  table.insert(vertices, vertex)
end

-- create mesh edges
write("Creating polygonal mesh from provided txt file (" .. file .. ") ...")
ClearSelection(mesh)
for index, _ in pairs(vertices) do
  if (index < lastIndex) then
     SelectVertexByIndex(mesh, index-1)
     SelectVertexByIndex(mesh, index)
     CreateEdge(mesh, subsetIndex)
     ClearSelection(mesh)
  end
end

ClearSelection(mesh)
SelectVertexByIndex(mesh, lastIndex-1)
SelectVertexByIndex(mesh, subsetIndex)
CreateEdge(mesh, subsetIndex)
ClearSelection(mesh)

----------------------------------------------------
--- rectangle
----------------------------------------------------
CreateVertex(mesh, MakeVec(v1.x, v1.y, zCoordinate), 2)
CreateVertex(mesh, MakeVec(v2.x, v2.y, zCoordinate), 2)
CreateVertex(mesh, MakeVec(v3.x, v3.y, zCoordinate), 2)
CreateVertex(mesh, MakeVec(v4.x, v4.y, zCoordinate), 2)
ClearSelection(mesh)
SelectVertexByIndex(mesh, 6)
SelectVertexByIndex(mesh, 7)
CreateEdge(mesh, 3)
ClearSelection(mesh)
SelectVertexByIndex(mesh, 6)
SelectVertexByIndex(mesh, 8)
CreateEdge(mesh, 4)
ClearSelection(mesh)
SelectVertexByIndex(mesh, 7)
SelectVertexByIndex(mesh, 9)
CreateEdge(mesh, 5)
ClearSelection(mesh)
SelectVertexByIndex(mesh, 9)
SelectVertexByIndex(mesh, 8)
CreateEdge(mesh, 6)

----------------------------------------------------
--- remove doubles and (isotropic) refinement
----------------------------------------------------
SelectAll(mesh)
RemoveDoubles(mesh, 0.0001)
EraseEmptySubsets(mesh)
for i=1, numRefinements do Refine(mesh) end

----------------------------------------------------
--- triangulation
----------------------------------------------------
SelectAll(mesh)
TriangleFill(mesh, true, minAngle, 6)
ClearSelection(mesh)

----------------------------------------------------
--- rectangle vertices assignment
----------------------------------------------------
SelectVertexByIndex(mesh, 6)
AssignSubset(mesh, 3)
AssignSubsetColors(mesh)
ClearSelection(mesh)
SelectVertexByIndex(mesh, 7)
AssignSubset(mesh, 2)
AssignSubsetColors(mesh)
ClearSelection(mesh)
SelectVertexByIndex(mesh, 8)
AssignSubset(mesh, 5)
AssignSubsetColors(mesh)
ClearSelection(mesh)
SelectVertexByIndex(mesh, 9)
AssignSubset(mesh, 4)

----------------------------------------------------
--- color subsets
----------------------------------------------------
AssignSubsetColors(mesh)
ClearSelection(mesh)

SelectSubset(mesh, 0, true, true, false, false)
SeparateFacesBySelectedEdges(mesh)

----------------------------------------------------
--- assign tower and box faces to separated subsets
----------------------------------------------------
ClearSelection(mesh)
SelectSubset(mesh, 0, true, true, true, false)
SelectSubset(mesh, 6, true, true, true, false)
AssignSubset(mesh, 0)
ClearSelection(mesh)
SelectSubset(mesh, 1, true, true, true, false)
CloseSelection(mesh)
AssignSubset(mesh, 1)
ClearSelection(mesh)
SelectSubsetBoundary(mesh, 1, true, true, false)
CloseSelection(mesh)
AssignSubset(mesh, 7)
ClearSelection(mesh)
EraseEmptySubsets(mesh)
print(" done!")
