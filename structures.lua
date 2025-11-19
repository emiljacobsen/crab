local structures = {}

local util = require "utility"

local walls = {}
local obstacles = {}

local function triords_to_wall_string(triord1, triord2)
   return
      util.triord_to_string(triord1)
      .. ";"
      .. util.triord_to_string(triord2)
end

local function wall_string_to_triords(wall_string)
   local _, _, h1, f1, b1, h2, f2, b2 =
      string.find(wall_string, "(.+),(.+),(.+);(.+),(.+),(.+)")
   return { { h1, f1, b1 }, { h2, f2, b2 } }

end

function structures.add_wall(triord1, triord2)
   walls[triords_to_wall_string(triord1, triord2)] = true
   walls[triords_to_wall_string(triord2, triord1)] = true
end

function structures.check_wall(triord1, triord2)
   return walls[triords_to_wall_string(triord1, triord2)] or false
end

function structures.get_walls()
   local triord_pairs = {}

   for wall_string, exists in pairs(walls) do
      if exists then
         triord_pairs[#triord_pairs+1] = wall_string_to_triords(wall_string)
      end
   end

   return triord_pairs
end

function structures.add_obstacle(triord)
   obstacles[table.concat(triord, ",")] = true
end

function structures.check_obstacle(triord)
   return obstacles[table.concat(triord, ",")] or false
end

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