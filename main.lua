
-- Geometry explainer:
-- - The arena is hexagonal.
-- - The `side_number` is the number of triangles
--   sharing a side with a particular side of the arena.
-- - Can populate the triangle collection row-wise,
--   with `side_number` × 2 rows,
--   and `side_number` × 2 + 1 + 2 * (r - 1)
--   triangles in the rth row.

-- Imports

local arena = require "arena"

-- Shorthands:

local gfx = love.graphics

-- Vars scoped to file:

love.window.setMode(1000, 600)
local width = gfx.getWidth()
local height = gfx.getHeight()
local font = gfx.newFont("fonts/gerhaus.ttf", 20)

local sqrt2 = math.sqrt(2)
local sqrt3 = math.sqrt(3)

local side_number = 3

local dirs = {
   h = 0,
   f = 1,
   b = 2
}

local triangles = {}
local player_pos = { 1, 1, 1 }
local player_dir = dirs.h
local spinner_pos = { 4, -2, 2 }
local spinner_dir = dirs.h
local walls = {}
local obstacles = {}

-- TODO: move wall & obstacle stuff to arena.lua

local function triord_to_string(triord)
      return table.concat(triord, ",")
end

local function triords_to_wall_string(triord1, triord2)
   return triord_to_string(triord1) .. ";" .. triord_to_string(triord2)
end

local function string_to_triord(triord_string)
   local _, _, h, f, b = string.find(triord_string, "(.+),(.+),(.+)")
   return { h, f, b }
end

local function wall_string_to_triords(wall_string)
   local _, _, h1, f1, b1, h2, f2, b2 =
      string.find(wall_string, "(.+),(.+),(.+);(.+),(.+),(.+)")
   return { { h1, f1, b1 }, { h2, f2, b2 } }

end

local function add_wall(triord1, triord2)
   walls[triords_to_wall_string(triord1, triord2)] = true
   walls[triords_to_wall_string(triord2, triord1)] = true
end

local function check_wall(triord1, triord2)
   return walls[triords_to_wall_string(triord1, triord2)] or false
end

local function wall_to_line(wall_string)
   local triords = wall_string_to_triords(wall_string)
   return arena.get_wall_line(triords[1], triords[2])
end

local function obstacle_to_vertices(obstacle_string)
   local triord = string_to_triord(obstacle_string)
   return arena.get_vertices(triord[1], triord[2], triord[3])
end

local function check_obstacle(triord)
   return obstacles[table.concat(triord, ",")] or false
end

local function add_obstacle(triord)
   obstacles[table.concat(triord, ",")] = true
end

-- TODO: maybe add these get_blah's to arena.lua?

local function get_left()
   return arena.get_adjacent(
      player_pos[1],
      player_pos[2],
      player_pos[3],
      (player_dir + 1) % 3
   )
end

local function get_left_better(triord, dir)
   return arena.get_adjacent(
      triord[1],
      triord[2],
      triord[3],
      (dir + 1) % 3
   )
end


local function get_right()
   return arena.get_adjacent(
      player_pos[1],
      player_pos[2],
      player_pos[3],
      (player_dir - 1) % 3
   )
end

local function get_behind()
   return arena.get_adjacent(
      player_pos[1],
      player_pos[2],
      player_pos[3],
      player_dir
   )
end

local function get_hexagon()
   local triords = {}
   local dir = player_dir
   triords[1] = player_pos
   for i = 2, 6 do
      -- TODO this is repeating code from get_right
      triords[i] = arena.get_adjacent(
         triords[i-1][1],
         triords[i-1][2],
         triords[i-1][3],
         (dir - 1) % 3
      )
     dir = (dir + 1) % 3
   end
   return triords
end

-- Runs on startup: 
function love.load()

   -- TODO: remove the + 80
   arena.setup(side_number, { 0, 0 + 40 }, { width, height + 40 })
   triangles = arena.get_all_triangles()

   add_wall({1, 1, 1}, {2, 1, 1})
   add_wall({1, 1, 2}, {1, 0, 2})
   add_wall({4,-1,1}, {4,-2,1})
   add_wall({4,-1,0}, {4,0,0})
   add_wall({3,-1,1},{3,0,1})
   add_obstacle({3,-2,2})
end

-- Runs every frame:
function love.update(dt)
end

-- Callback function for keypresses
function love.keypressed(key)

   local moving_to = nil
   local new_dir = player_dir

   if key == 's' then
      moving_to = get_behind()
   elseif key == 'a' then
      moving_to = get_left()
      new_dir = (player_dir - 1) % 3
   elseif key == 'd' then
      moving_to = get_right()
      new_dir = (player_dir + 1) % 3
   end

   if moving_to ~= nil
      and not check_wall(player_pos, moving_to)
      and not check_obstacle(moving_to)
   then
      player_pos = moving_to
      player_dir = new_dir

      spinner_pos = get_left_better(spinner_pos, spinner_dir)
      spinner_dir = (spinner_dir - 1) % 3
   end

   -- Put debug info here.
   if key == 'space' then
      print("Pressed space")
      print("Current triords:", table.concat(player_pos, ", "))
   end
end

function love.mousepressed(x, y, button, istouch, presses)

   if not button == 1 then return end

   local moving_to = nil

   local h = 1 +
      math.floor((y - 40) / arena.diametre)

   local f_offset_vertex = arena.get_h_vertex(1, 1, 1)
   local f_offset = -f_offset_vertex[1] - (f_offset_vertex[2] - 40) / sqrt3
   local f = 2 +
      math.floor((-x - (y - 40) / sqrt3 - f_offset) / arena.side)

   local b_offset_vertex =
      arena.get_h_vertex(1, 1 - arena.scale, 1 + arena.scale)
   local b_offset =
      b_offset_vertex[1] - (b_offset_vertex[2] - 40) / sqrt3
   local b = 5 +
      math.floor((x - (y - 40) / sqrt3 - b_offset) / arena.side)

   local tristring = h .. "," .. f .. "," .. b

   local left = get_left()
   local right = get_right()
   local behind = get_behind()

   local new_dir = player_dir

   if tristring == triord_to_string(left) then
      moving_to = left
      new_dir = (player_dir - 1) % 3
   elseif tristring == triord_to_string(right) then
      moving_to = right
      new_dir = (player_dir + 1) % 3
   elseif tristring == triord_to_string(behind) then
      moving_to = behind
   end

   if moving_to ~= nil and
      not check_obstacle(moving_to) and
      not check_wall(player_pos, moving_to)
   then
      player_pos = moving_to
      player_dir = new_dir
   end

end

-- Draw function
function love.draw()

   -- Mark the current hexagon

   local hex_triords = get_hexagon()
   gfx.setColor(0.4, 0.4, 0.4, 0.5)
   for _, triord in ipairs(hex_triords) do
      local vertices = arena.get_vertices(triord[1], triord[2], triord[3])
      gfx.polygon("fill", vertices)
   end

   -- Draw the arena
   for _, vertices in ipairs(triangles) do
      gfx.setColor(1, 1, 1)
      gfx.polygon("line", vertices)
   end

   -- Draw red dots on player adjacent triangles

   gfx.setColor(1, 0, 0)
   local adjacent = get_left()
   local adj_centre = arena.get_centre(adjacent[1], adjacent[2], adjacent[3])
   if not check_wall(player_pos, adjacent)
      and not check_obstacle(adjacent)
   then
      gfx.circle("fill", adj_centre[1], adj_centre[2], arena.diametre / 12)
   end

   gfx.setColor(0, 1, 0)
   local adjacent = get_right()
   local adj_centre = arena.get_centre(adjacent[1], adjacent[2], adjacent[3])
   if not check_wall(player_pos, adjacent)
      and not check_obstacle(adjacent)
   then
      gfx.circle("fill", adj_centre[1], adj_centre[2], arena.diametre / 12)
   end

   gfx.setColor(1, 1, 0)
   local adjacent = get_behind()
   local adj_centre = arena.get_centre(adjacent[1], adjacent[2], adjacent[3])
   if not check_wall(player_pos, adjacent)
      and not check_obstacle(adjacent)
   then
      gfx.circle("fill", adj_centre[1], adj_centre[2], arena.diametre / 12)
   end

   -- Draw walls

   gfx.setColor(1, 1, 1)
   gfx.setLineWidth(5)
   for wall_string, maybe in pairs(walls) do
      if maybe then
         local line = wall_to_line(wall_string)
         gfx.line(line[1], line[2], line[3], line[4])
      end
   end
   gfx.setLineWidth(1)

   -- Draw obstacles

   gfx.setColor(1, 1, 1)
   for obstacle_string, maybe in pairs(obstacles) do
      if maybe then
         gfx.polygon("fill", obstacle_to_vertices(obstacle_string))
      end
   end

   -- Draw the player

   local pc =
      arena.get_centre(player_pos[1], player_pos[2], player_pos[3])

   -- Draw a circle where the player is

   gfx.setColor(1, 1, 1)
   gfx.circle("line", pc[1], pc[2], arena.side/6)

   -- Draw a line from the circle to where the player is looking

   local looking_at = {}
   if player_dir == dirs.h then
      looking_at =
         arena.get_h_vertex(player_pos[1], player_pos[2], player_pos[3])
   elseif player_dir == dirs.f then
      looking_at =
         arena.get_f_vertex(player_pos[1], player_pos[2], player_pos[3])
   elseif player_dir == dirs.b then
      looking_at =
         arena.get_b_vertex(player_pos[1], player_pos[2], player_pos[3])
   end
   local look_line = { pc[1], pc[2], looking_at[1], looking_at[2] }
   gfx.line(look_line)

   -- Draw a white point where the player is looking

   gfx.circle("fill", looking_at[1], looking_at[2], arena.side / 20)

   -- Draw a "spinner" "enemy"

   local sc =
      arena.get_centre(spinner_pos[1], spinner_pos[2], spinner_pos[3])

   -- Draw a circle where the spinner is

   gfx.setColor(1, 0, 0)
   gfx.circle("fill", sc[1], sc[2], arena.side/10)

   -- Draw a line from the circle to where the spinner is looking

   if spinner_dir == dirs.h then
      looking_at =
         arena.get_h_vertex(spinner_pos[1], spinner_pos[2], spinner_pos[3])
   elseif spinner_dir == dirs.f then
      looking_at =
         arena.get_f_vertex(spinner_pos[1], spinner_pos[2], spinner_pos[3])
   elseif spinner_dir == dirs.b then
      looking_at =
         arena.get_b_vertex(spinner_pos[1], spinner_pos[2], spinner_pos[3])
   end
   look_line = { sc[1], sc[2], looking_at[1], looking_at[2] }
   gfx.line(look_line)

   -- Draw a dot where the spinner is looking

   gfx.circle("fill", looking_at[1], looking_at[2], arena.side / 20)

   -- Draw UI

   gfx.setColor(1, 0, 0)
   local explainer_a = gfx.newText(font, "'a' to go clockwise")
   gfx.draw(explainer_a, 640, 10)

   gfx.setColor(0, 1, 0)
   local explainer_d = gfx.newText(font, "'d' to go counter clockwise")
   gfx.draw(explainer_d, 640, 40)

   gfx.setColor(1, 1, 0)
   local explainer_s = gfx.newText(font, "'s' to flip backwards")
   gfx.draw(explainer_s, 640, 70)

   -- Debugging message in upper left corner

   local mouse_x, mouse_y = love.mouse.getPosition()

   -- TODO: get rid of the 40 offset (should be in a variable)

   local h_test = 1 +
      math.floor((mouse_y - 40) / arena.diametre)

   local f_offset_vertex = arena.get_h_vertex(1, 1, 1)
   local f_offset = -f_offset_vertex[1] - (f_offset_vertex[2] - 40) / sqrt3
   local f_test = 2 +
      math.floor((-mouse_x - (mouse_y - 40) / sqrt3 - f_offset) / arena.side)

   local b_offset_vertex =
      arena.get_h_vertex(1, 1 - arena.scale, 1 + arena.scale)
   local b_offset =
      b_offset_vertex[1] - (b_offset_vertex[2] - 40) / sqrt3
   local b_test = 5 +
      math.floor((mouse_x - (mouse_y - 40) / sqrt3 - b_offset) / arena.side)

   gfx.setColor(1, 1, 1)
   local debug_string =
      "h: " .. h_test
      .. " ; " ..
      "f: " .. f_test
      .. " ; " ..
      "b: " .. b_test
   local debug_text = gfx.newText(font, debug_string)
   gfx.draw(debug_text, 10, 10)

   local mouse_pos_string = "x: " .. mouse_x .. " ; y: " .. mouse_y
   gfx.draw(gfx.newText(font, mouse_pos_string), 10, 40)

   -- local test_val = math.floor(mouse_x - (mouse_y - 40) / sqrt3)
   -- gfx.draw(gfx.newText(font, test_val), 10, 70)
end
