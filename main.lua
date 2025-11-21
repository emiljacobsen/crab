
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
local draw = require "draw"

-- Shorthands:

local gfx = love.graphics

-- Vars scoped to file:

love.window.setMode(1000, 600)
local width = gfx.getWidth()
local height = gfx.getHeight()
local font = gfx.newFont("fonts/gerhaus.ttf", 20)

-- TODO: Deal with this in a better (automatic) way
ARENA_Y_OFFSET = 40

-- The number of triangles along a side of the arena
local scale = 3

-- Did the player just move?
local moved = false
-- Can the player move now?
local can_move = true
-- When did the player last move?
local moved_time = nil

-- Runs on startup: 
function love.load()

   grid.setup(scale)
   arena.setup(
      grid,
      { 0, 0 + ARENA_Y_OFFSET },
      { width, height + ARENA_Y_OFFSET })
   draw.setup(arena)
   ent.setup(grid, str)

   -- Manually add some walls and an obstacle (for now)

   str.add_wall({1, 1, 1}, {2, 1, 1})
   str.add_wall({1, 1, 2}, {1, 0, 2})
   str.add_wall({4,-1,1}, {4,-2,1})
   str.add_wall({4,-1,0}, {4,0,0})
   str.add_wall({3,-1,1},{3,0,1})
   str.add_wall({2,-1,3},{2,-2,3})
   str.add_wall({4,0,-1},{4,0,0})
   str.add_obstacle({3,-2,2})
end

-- Runs every frame:
function love.update(dt)
   if moved and love.timer.getTime() - moved_time > 0.1 then
      ent.move_hazards()

      moved = false
      can_move = true
   end
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

   -- TODO: should record the input and move the player once it's ok to move?
   if can_move then
      moved, moved_time = ent.move_player(moving_to, new_dir)
      can_move = not moved
   end

   -- Put debug info here.
   if key == 'space' then
      print("Pressed space")
      print("Current triords:", table.concat(ent.player.pos, ", "))
   end
end

-- Runs when a mouse button is pressed
function love.mousepressed(x, y, button, istouch, presses)

   -- Only interested in left click
   if not button == 1 then return end

   local moving_to = nil
   local new_dir = ent.player.dir

   -- This is a string representing the clicked triangle
   local tristring = util.triord_to_string(arena.coord_to_triord(x, y))

   -- Here are the three adjacent triangles

   local left = grid.get_left(ent.player.pos, ent.player.dir)
   local right = grid.get_right(ent.player.pos, ent.player.dir)
   local behind = grid.get_behind(ent.player.pos, ent.player.dir)

   -- Check if the clicked triangle is adjacent,
   -- if so, set the new pos and dir accordingly

   if tristring == util.triord_to_string(left) then
      moving_to = left
      new_dir = (ent.player.dir - 1) % 3
   elseif tristring == util.triord_to_string(right) then
      moving_to = right
      new_dir = (ent.player.dir + 1) % 3
   elseif tristring == util.triord_to_string(behind) then
      moving_to = behind
   end

   -- Try to move if it's the players turn
   if can_move then
      moved, moved_time = ent.move_player(moving_to, new_dir)
      can_move = not moved
   end

end

function love.draw()

   -- Highlight the current hexagon
   local hex_triords = grid.get_hexagon(ent.player.pos, ent.player.dir)
   for _, triord in ipairs(hex_triords) do
      draw.highlight_triangle(triord)
   end

   -- Draw the arena
   draw.arena()

   -- Draw walls
   draw.walls(str.get_walls())

   -- Draw obstacles
   draw.obstacles(str.get_obstacles())

   -- Draw hazards
   draw.hazards(ent.hazards)

   -- Draw the player (need to pass on adjacent, accessible triords)

   local left = grid.get_left(ent.player.pos, ent.player.dir)
   if str.check_wall(ent.player.pos, left)
      or str.check_obstacle(left)
   then
      left = nil
   end

   local right = grid.get_right(ent.player.pos, ent.player.dir)
   if str.check_wall(ent.player.pos, right)
      or str.check_obstacle(right)
   then
      right = nil
   end

   local behind = grid.get_behind(ent.player.pos, ent.player.dir)
   if str.check_wall(ent.player.pos, behind)
      or str.check_obstacle(behind)
   then
      behind = nil
   end

   draw.player(ent.player, left, right, behind)

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

   gfx.setColor(1, 1, 1)
   local test = arena.coord_to_triord(mouse_x, mouse_y)
   local debug_string =
      "h: " .. test[1]
      .. " ; " ..
      "f: " .. test[2]
      .. " ; " ..
      "b: " .. test[3]
   local debug_text = gfx.newText(font, debug_string)
   gfx.draw(debug_text, 10, 10)
end
