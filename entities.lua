local entities = {}

local grid = nil
local str = nil

entities.player = nil
entities.spinners = nil

function entities.setup(grid_arg, structure_arg)
   grid = grid_arg
   str = structure_arg

   entities.player = {
      pos = { 1, 1, 1 },
      dir = grid.dirs.h
   }

   entities.spinners = {
      {
         pos = { 4, -2, 2 },
         dir = grid.dirs.h
      },
      {
         pos = { 3, 1, 0 },
         dir = grid.dirs.h
      },
      {
         pos = { 5, 0, -1 },
         dir = grid.dirs.h
      }
   }
end

function entities.move_spinners()
   for _, s in pairs(entities.spinners) do
      local new_pos = grid.get_left(s.pos, s.dir)
      if not str.check_obstacle(new_pos)
         and not str.check_wall(s.pos, new_pos)
         and new_pos ~= entities.player.pos
      then
         s.pos = new_pos
         s.dir = (s.dir - 1) % 3
      end
   end
end

return entities