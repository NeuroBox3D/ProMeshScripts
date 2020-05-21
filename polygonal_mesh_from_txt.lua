--------------------------------------------------------------------------------
-- This script creates a 2d polygonal mesh from provided txt data             --
-- Usage: Copy and paste into ProMesh's live script editor and apply          --
--                                                                            --
-- Note: Make sure file path of the txt file points to a valid location       --
--                                                                            --
-- Author: Stephan Grein                                                      --
-- Date:   05-21-2020                                                         --
--------------------------------------------------------------------------------
-- path to file
local file = '/Users/stephan/test.txt'

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
print(" done!")
