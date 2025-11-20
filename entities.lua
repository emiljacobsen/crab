local entities = {}

local util = require "utility"

local grid = nil
local str = nil

entities.player = nil
entities.hazards = nil

function entities.setup(grid_arg, structure_arg)
   grid = grid_arg
   str = structure_arg

   entities.player = {
      pos = { 1, 1, 1 },
      dir = grid.dirs.h
   }

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
         }
      },
      walkers = {
         {
            pos = { 5, -1, -1 },
            avoid = grid.dirs.h,
            sign = -1
         }
      }
   }
end

local function check_player(triord)
   return util.triord_to_string(triord)
      == util.triord_to_string(entities.player.pos)
end

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

function entities.move_player(move_to, new_dir)

   if move_to == nil then
      return false, love.timer.getTime()
   end

   local hazard_blocking, hazard_type, hazard_key = check_hazard(move_to)

   if str.check_obstacle(move_to)
      or str.check_wall(entities.player.pos, move_to)
      or hazard_blocking
   then
      if hazard_blocking then
         entities.hazards[hazard_type][hazard_key] = nil
      end

      return false, love.timer.getTime()
   end

   entities.player.pos = move_to
   entities.player.dir = new_dir

   return true, love.timer.getTime()
end

local function spinner_new_pos(spinner)
   local new_pos = nil

   if spinner.sign == 1 then 
      new_pos = grid.get_right(spinner.pos, spinner.dir)
   elseif spinner.sign == -1 then
      new_pos = grid.get_left(spinner.pos, spinner.dir)
   end

   return new_pos, (spinner.dir + spinner.sign) % 3
end

local function walker_new_pos(walker)
   local sign =
      walker.sign * grid.get_sign(walker.pos[1], walker.pos[2], walker.pos[3])
   local move_dir = (walker.avoid + sign) % 3
   return grid.get_adjacent(
      walker.pos[1],
      walker.pos[2],
      walker.pos[3],
      move_dir
   )
end

local function hazard_new_pos(hazard, type)
   if type == "spinners" then
      return spinner_new_pos(hazard)
   elseif type == "walkers" then
      return walker_new_pos(hazard)
   else
      error("Bad hazard type: " .. type)
   end
end

local function try_move_hazard(hazard, type)
   local new_pos, new_dir = hazard_new_pos(hazard, type)
   if check_player(new_pos) then
      return false, true
   end

   if not str.check_obstacle(new_pos)
      and not str.check_wall(hazard.pos, new_pos)
      and not check_player(new_pos)
   then
      hazard.pos = new_pos
      hazard.dir = new_dir
      return true, false
   else
      return false, false
   end
end

function entities.move_hazards()

   for type, hazards in pairs(entities.hazards) do
      for _, h in pairs(hazards) do
         local moved, attacked = try_move_hazard(h, type)

         -- If there was a collision, try to go the other way
         if not moved and not attacked then
            h.sign = -1 * h.sign
            moved, attacked = try_move_hazard(h, type)
         end

         if attacked then
            -- TODO
         end
      end
   end
end

return entities