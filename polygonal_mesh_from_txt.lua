--------------------------------------------------------------------------------
-- path to 2d polygon tower
local files = {
   '/Users/stephan/test.txt' -- 1st tower
}

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

  local zCoordinate = 0 -- fix 3rd coordinate

----------------------------------------------------
--- create tower(s)
----------------------------------------------------
-- read lines from file (each line represents a 2d coordinate)
local currentIndex = 0
local subsetIndex = -1
local lastIndex = 0
for fileindex, file in pairs(files) do
  local lines = lines_from(file)
  lastIndex = lastIndex + #lines -- current last index needs to get updated each iteration
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
  write("Creating polygonal mesh from provided txt file (" .. file .. ") ...")
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
  SelectVertexByIndex(mesh, lastIndex-1) -- last vertex
  SelectVertexByIndex(mesh, currentIndex) -- first vertex
  CreateEdge(mesh, subsetIndex)
  ClearSelection(mesh)
  currentIndex = currentIndex+#lines
end

----------------------------------------------------
--- rectangle
----------------------------------------------------
rectIndex=subsetIndex+1 -- subset index for rectangle
CreateVertex(mesh, MakeVec(v1.x, v1.y, zCoordinate), rectIndex)
CreateVertex(mesh, MakeVec(v2.x, v2.y, zCoordinate), rectIndex)
CreateVertex(mesh, MakeVec(v3.x, v3.y, zCoordinate), rectIndex)
CreateVertex(mesh, MakeVec(v4.x, v4.y, zCoordinate), rectIndex)
ClearSelection(mesh)

----------------------------------------------------
--- rectangle boundary
----------------------------------------------------
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
TriangleFill(mesh, true, minAngle, rectIndex+5)
ClearSelection(mesh)

----------------------------------------------------
--- rectangle vertices assignment
----------------------------------------------------
SelectVertexByIndex(mesh, currentIndex)
AssignSubset(mesh, rectIndex+1)
AssignSubsetColors(mesh)
ClearSelection(mesh)
SelectVertexByIndex(mesh, currentIndex+1)
AssignSubset(mesh, rectIndex+3)
AssignSubsetColors(mesh)
ClearSelection(mesh)
SelectVertexByIndex(mesh, currentIndex+2)
AssignSubset(mesh, rectIndex)
AssignSubsetColors(mesh)
ClearSelection(mesh)
SelectVertexByIndex(mesh, currentIndex+3)
AssignSubset(mesh, rectIndex+2)

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
subsetOffset=5 -- left,right,top,bottom boundaries...
SelectSubset(mesh, 0, true, true, true, false)
SelectSubset(mesh, rectIndex+subsetOffset, true, true, true, false)
AssignSubset(mesh, 0)
for i, file in pairs(files) do
  ClearSelection(mesh)
  SelectSubset(mesh, 1+(subsetOffset*(i-1)), true, true, true, false)
  CloseSelection(mesh)
  AssignSubset(mesh, 1+(subsetOffset*(i-1)))
  ClearSelection(mesh)
  SelectSubsetBoundary(mesh, 1+subsetOffset*(i-1), true, true, false)
  CloseSelection(mesh)
  AssignSubset(mesh, 1+(subsetOffset*i))
  ClearSelection(mesh)
  EraseEmptySubsets(mesh)
end
print(" done!")
