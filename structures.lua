local structures = {}

-- Imports

local util = require "utility"

-- Vars scoped to file

-- A list of wall pairs { triord1, triord2 }
-- with each triord of the form { h, f, b }.
local walls = {}
-- A list of triordinates { { h, f, b }, ... }.
local obstacles = {}

-- Convert a wall pair to a string.
-- Returns a string.
local function wall_pair_to_string(triord1, triord2)
   return
      util.triord_to_string(triord1)
      .. ";"
      .. util.triord_to_string(triord2)
end

-- Convert a (wall) string to a wall pair.
-- Returns a pair { triord1, triord2 }.
local function string_to_wall_pair(wall_string)
   local _, _, h1, f1, b1, h2, f2, b2 =
      string.find(wall_string, "(.+),(.+),(.+);(.+),(.+),(.+)")
   return { { h1, f1, b1 }, { h2, f2, b2 } }
end

-- Add a wall between triord1 and triord2.
function structures.add_wall(triord1, triord2)
   walls[wall_pair_to_string(triord1, triord2)] = true
   walls[wall_pair_to_string(triord2, triord1)] = true
end

-- Check if there's a wall between triord1 and triord2.
function structures.check_wall(triord1, triord2)
   return walls[wall_pair_to_string(triord1, triord2)] or false
end

-- Get all wall pairs in an array.
function structures.get_walls()
   local triord_pairs = {}

   for wall_string, exists in pairs(walls) do
      if exists then
         triord_pairs[#triord_pairs+1] = string_to_wall_pair(wall_string)
      end
   end

   return triord_pairs
end

-- Add an obstacle at triord.
function structures.add_obstacle(triord)
   obstacles[table.concat(triord, ",")] = true
end

-- Check if there's an obstacle at triord.
function structures.check_obstacle(triord)
   return obstacles[table.concat(triord, ",")] or false
end

-- Get all obstacle triords in an array.
function structures.get_obstacles()
   local triords = {}

   for obs_string, exists in pairs(obstacles) do
      if exists then
         triords[#triords+1] = util.string_to_triord(obs_string)
      end
   end

   return triords
end

return structures