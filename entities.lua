local entities = {}

local grid = require "grid"

entities.player = {
   pos = { 1, 1, 1 },
   dir = grid.dirs.h
}

entities.spinners = {
   {
      pos = { 4, -2, 2 },
      dir = grid.dirs.h
   }
}

return entities