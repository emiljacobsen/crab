local entities = {}

-- Imports

local util = require "utility"

-- Need these to be the instances from main.lua

local grid = nil
local str = nil

-- The player table, with fields pos and dir.
entities.player = nil

-- The hazards table, with fields spinners, walkers, ...
-- Each field is itself a table of tables,
-- finally with fields pos, sign, and more.
--
-- Spinners have a `pos` and `dir`, like the player,
-- and always move left or right depending on `sign`.
--
-- Walkers have a `pos`, a `sign`, and an `avoid`.
-- The latter takes one of the `grid.dirs` values,
-- and records which type of line to avoid crossing.
-- It then moves in its lane, in a direction set by `sign`.
entities.hazards = nil

-- Need grid_arg and structure_arg to be the instances
-- of grid and structure from main.lua.
function entities.setup(grid_arg, structure_arg)
   grid = grid_arg
   str = structure_arg

   -- Set the initial player position.
   entities.player = {
      pos = { 1, 1, 1 },
      dir = grid.dirs.h,
      health = 2
   }

   -- Manually populate hazards, for now.
   entities.hazards = {

      spinners = {
         {
            pos = { 4, -2, 2 },
            dir = grid.dirs.h,
            sign = 1
         },
         {
            pos = { 3, 1, 0 },
            dir = grid.dirs.h,
            sign = -1
         },
         {
            pos = { 5, 0, -1 },
            dir = grid.dirs.h,
            sign = 1
         },
         {
            pos = { 3, -3, 4 },
            dir = grid.dirs.f,
            sign = 1
         }
      },

      walkers = {
         {
            pos = { 5, -1, -1 },
            avoid = grid.dirs.h,
            sign = -1
         },
         {
            pos = { 3, -1, 1 },
            avoid = grid.dirs.f,
            sign = 1
         }
      }

   }
end

-- Returns true if the player is at the triangle `triord`.
local function check_player(triord)
   return util.triord_to_string(triord)
      == util.triord_to_string(entities.player.pos)
end

-- Returns bool, string, string.
-- The bool is true if there's a hazard at `triord`.
-- The two strings identify the hazard
-- (as entities.hazards[type][key]).
local function check_hazard(triord)
   for type, hazards in pairs(entities.hazards) do
      for key, hazard in pairs(hazards) do
         if util.triord_to_string(triord)
            == util.triord_to_string(hazard.pos)
         then
            return true, type, key
         end
      end
   end

   return false, nil, nil
end

-- Try to move the player.
-- Returns a bool and a time.
-- The time is the current time,
-- and the bool is true if the player
-- was able to move to `move_to`.
-- Also returns true if the player attacked instead of moved.
function entities.move_player(move_to, new_dir)

   if move_to == nil then
      return false, love.timer.getTime()
   end

   local hazard_blocking, hazard_type, hazard_key = check_hazard(move_to)

   if str.check_obstacle(move_to)
      or str.check_wall(entities.player.pos, move_to)
      -- or hazard_blocking
   then
      return false, love.timer.getTime()
   end

   if hazard_blocking then
      -- Kill the hazard the player walked into
      entities.hazards[hazard_type][hazard_key] = nil
      -- Stand still
      move_to = entities.player.pos
      new_dir = entities.player.dir
   end

   -- If we got here, the player was able to move.
   -- Update their pos and dir:

   entities.player.pos = move_to
   entities.player.dir = new_dir

   return true, love.timer.getTime()
end

-- Compute the direction the spinner is going to try to move in.
local function spinner_going_towards(spinner)
   return (spinner.dir - spinner.sign) % 3
end

-- Compute the next pos of a spinner.
-- Returns `new_pos`, `new_dir`, where
-- `new_pos` is a triordinate { h, f, b },
-- `new_dir` is a member of `grid.dirs`
local function spinner_new_pos(spinner)
   local new_pos = grid.get_adjacent(
      spinner.pos[1],
      spinner.pos[2],
      spinner.pos[3],
      spinner_going_towards(spinner))

   return new_pos, (spinner.dir + spinner.sign) % 3
end

-- Compute the direction the walker is going to try to move in.
local function walker_going_towards(walker)
   local sign =
      walker.sign * grid.get_sign(walker.pos[1], walker.pos[2], walker.pos[3])
   return (walker.avoid + sign) % 3
end

-- Compute the next pos of a walker.
-- Returns a triordinate { h, f, b }.
local function walker_new_pos(walker)
   return grid.get_adjacent(
      walker.pos[1],
      walker.pos[2],
      walker.pos[3],
      walker_going_towards(walker))
end

-- Compute the next pos of a hazard.
function entities.hazard_new_pos(hazard, type)
   if type == "spinners" then
      return spinner_new_pos(hazard)
   elseif type == "walkers" then
      return walker_new_pos(hazard)
   else
      error("Bad hazard type: " .. type)
   end
end

-- Try to move a hazard.
-- Returns bools `moved`, `attacked`, newpos.
-- The latter is true when the hazard tried to move into the player.
local function try_move_hazard(hazard, type)
   local new_pos, new_dir = entities.hazard_new_pos(hazard, type)
   if check_player(new_pos) then
      return false, true, new_pos, new_dir
   end

   if not str.check_obstacle(new_pos)
      and not str.check_wall(hazard.pos, new_pos)
      and not check_player(new_pos)
   then
      return true, false, new_pos, new_dir
   else
      return false, false, new_pos, new_dir
   end
end

-- (Try to) move all hazards
function entities.move_hazards()
   local new_pos_set = {}

   for type, hazards in pairs(entities.hazards) do

      for key, h in pairs(hazards) do

         local moved, attacked, new_pos, new_dir
            = try_move_hazard(h, type)

         local aux = new_pos_set[util.triord_to_string(new_pos)]
         if aux then
            moved = false
         end

         -- If there was a collision, try to go the other way
         if not moved and not attacked then
            h.sign = -1 * h.sign
            moved, attacked, new_pos, new_dir = try_move_hazard(h, type)
         end

         if attacked then
            entities.player.health = entities.player.health - 1
         end

         if moved == true then
            new_pos_set[util.triord_to_string(new_pos)] = { type, key }
            h.pos = new_pos
            h.dir = new_dir
         end

      end
   end
end

-- Returns the grid.dirs value corresponding to
-- which line the hazard is about to try and cross.
function entities.hazard_going_towards(hazard, type)
   if type == "spinners" then
      return spinner_going_towards(hazard)
   elseif type == "walkers" then
      return walker_going_towards(hazard)
   else
      error("Bad hazard type: " .. type)
   end
end

return entities