
-- Geometry explainer:
-- - The arena is hexagonal.
-- - The `side_number` is the number of triangles
--   sharing a side with a particular side of the arena.

-- Imports

local arena = require "arena"
local grid = require "grid"
local str = require "structures"
local util = require "utility"
local ent = require "entities"

-- Shorthands:

local gfx = love.graphics

-- Vars scoped to file:

love.window.setMode(1000, 600)
local width = gfx.getWidth()
local height = gfx.getHeight()
local font = gfx.newFont("fonts/gerhaus.ttf", 20)

local sqrt3 = math.sqrt(3)

local side_number = 3

local triangles = {}

-- Runs on startup: 
function love.load()

   -- TODO: remove the + 80
   grid.setup(side_number)
   arena.setup(grid, { 0, 0 + 40 }, { width, height + 40 })
   triangles = arena.get_all_triangle_vertices()

   str.add_wall({1, 1, 1}, {2, 1, 1})
   str.add_wall({1, 1, 2}, {1, 0, 2})
   str.add_wall({4,-1,1}, {4,-2,1})
   str.add_wall({4,-1,0}, {4,0,0})
   str.add_wall({3,-1,1},{3,0,1})
   str.add_obstacle({3,-2,2})
end

-- Runs every frame:
function love.update(dt)
end

-- Callback function for keypresses
function love.keypressed(key)

   local moving_to = nil
   local new_dir = ent.player.dir

   if key == 's' then
      moving_to = grid.get_behind(ent.player.pos, ent.player.dir)
   elseif key == 'a' then
      moving_to = grid.get_left(ent.player.pos, ent.player.dir)
      new_dir = (ent.player.dir - 1) % 3
   elseif key == 'd' then
      moving_to = grid.get_right(ent.player.pos, ent.player.dir)
      new_dir = (ent.player.dir + 1) % 3
   end

   if moving_to ~= nil
      and not str.check_wall(ent.player.pos, moving_to)
      and not str.check_obstacle(moving_to)
   then
      ent.player.pos = moving_to
      ent.player.dir = new_dir

      -- TODO: better implementation of spinner movement in entities.lua
      -- spinner_pos = grid.get_left(spinner_pos, spinner_dir)
      -- spinner_dir = (spinner_dir - 1) % 3
   end

   -- Put debug info here.
   if key == 'space' then
      print("Pressed space")
      print("Current triords:", table.concat(ent.player.pos, ", "))
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

   local left = grid.get_left(ent.player.pos, ent.player.dir)
   local right = grid.get_right(ent.player.pos, ent.player.dir)
   local behind = grid.get_behind(ent.player.pos, ent.player.dir)

   local new_dir = ent.player.dir

   if tristring == util.triord_to_string(left) then
      moving_to = left
      new_dir = (ent.player.dir - 1) % 3
   elseif tristring == util.triord_to_string(right) then
      moving_to = right
      new_dir = (ent.player.dir + 1) % 3
   elseif tristring == util.triord_to_string(behind) then
      moving_to = behind
   end

   if moving_to ~= nil and
      not str.check_obstacle(moving_to) and
      not str.check_wall(ent.player.pos, moving_to)
   then
      ent.player.pos = moving_to
      ent.player.dir = new_dir
   end

end

-- Draw function
function love.draw()

   -- Mark the current hexagon

   local hex_triords = grid.get_hexagon(ent.player.pos, ent.player.dir)
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

   local adjacent = {}
   local adj_centre = {}

   gfx.setColor(1, 0, 0)
   adjacent = grid.get_left(ent.player.pos, ent.player.dir)
   adj_centre = arena.get_centre(adjacent[1], adjacent[2], adjacent[3])
   if not str.check_wall(ent.player.pos, adjacent)
      and not str.check_obstacle(adjacent)
   then
      gfx.circle("fill", adj_centre[1], adj_centre[2], arena.diametre / 12)
   end

   gfx.setColor(0, 1, 0)
   adjacent = grid.get_right(ent.player.pos, ent.player.dir)
   adj_centre = arena.get_centre(adjacent[1], adjacent[2], adjacent[3])
   if not str.check_wall(ent.player.pos, adjacent)
      and not str.check_obstacle(adjacent)
   then
      gfx.circle("fill", adj_centre[1], adj_centre[2], arena.diametre / 12)
   end

   gfx.setColor(1, 1, 0)
   adjacent = grid.get_behind(ent.player.pos, ent.player.dir)
   adj_centre = arena.get_centre(adjacent[1], adjacent[2], adjacent[3])
   if not str.check_wall(ent.player.pos, adjacent)
      and not str.check_obstacle(adjacent)
   then
      gfx.circle("fill", adj_centre[1], adj_centre[2], arena.diametre / 12)
   end

   -- Draw walls

   gfx.setColor(1, 1, 1)
   gfx.setLineWidth(5)
   for _, wall_pair in ipairs(str.get_walls()) do
      local line = arena.get_wall_line(wall_pair[1], wall_pair[2])
      gfx.line(line[1], line[2], line[3], line[4])
   end
   gfx.setLineWidth(1)

   -- Draw obstacles

   gfx.setColor(1, 1, 1)
   for _, triord in ipairs(str.get_obstacles()) do
      gfx.polygon("fill", arena.get_vertices(triord[1], triord[2], triord[3]))
   end

   -- Draw the player

   local pc =
      arena.get_centre(ent.player.pos[1], ent.player.pos[2], ent.player.pos[3])

   -- Draw a circle where the player is

   gfx.setColor(1, 1, 1)
   gfx.circle("line", pc[1], pc[2], arena.side/6)

   -- Draw a line from the circle to where the player is looking

   local looking_at = {}
   if ent.player.dir == grid.dirs.h then
      looking_at =
         arena.get_h_vertex(ent.player.pos[1], ent.player.pos[2], ent.player.pos[3])
   elseif ent.player.dir == grid.dirs.f then
      looking_at =
         arena.get_f_vertex(ent.player.pos[1], ent.player.pos[2], ent.player.pos[3])
   elseif ent.player.dir == grid.dirs.b then
      looking_at =
         arena.get_b_vertex(ent.player.pos[1], ent.player.pos[2], ent.player.pos[3])
   end
   local look_line = { pc[1], pc[2], looking_at[1], looking_at[2] }
   gfx.line(look_line)

   -- Draw a white point where the player is looking

   gfx.circle("fill", looking_at[1], looking_at[2], arena.side / 20)

   -- Draw "spinners"

   gfx.setColor(1, 0, 0)
   for _, s in ipairs(ent.spinners) do
      local sc = arena.get_centre(s.pos[1], s.pos[2], s.pos[3])

      -- Draw a circle where the spinner is

      gfx.circle("fill", sc[1], sc[2], arena.side/10)

      -- Draw a line from the circle to where the spinner is looking

      looking_at = arena.get_vertex(s.pos[1], s.pos[2], s.pos[3], s.dir)
      look_line = { sc[1], sc[2], looking_at[1], looking_at[2] }
      gfx.line(look_line)

      -- Draw a dot where the spinner is looking

      gfx.circle("fill", looking_at[1], looking_at[2], arena.side / 20)

   end

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
