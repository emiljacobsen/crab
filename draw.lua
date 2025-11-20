local draw = {}

local arena = nil

local gfx = love.graphics

function draw.setup(arena_arg)
   arena = arena_arg
end

function draw.player(player, left, right, behind)

   -- Draw red dots on player adjacent triangles

   local centre = {}
   local dot_size = arena.diametre / 16

   gfx.setColor(1, 0, 0)
   if left ~= nil then
      centre = arena.get_centre(left[1], left[2], left[3])
      gfx.circle("fill", centre[1], centre[2], dot_size)
   end

   gfx.setColor(0, 1, 0)
   if right ~= nil then
      centre = arena.get_centre(right[1], right[2], right[3])
      gfx.circle("fill", centre[1], centre[2], dot_size)
   end

   gfx.setColor(1, 1, 0)
   if behind ~= nil then
      centre = arena.get_centre(behind[1], behind[2], behind[3])
      gfx.circle("fill", centre[1], centre[2], dot_size)
   end

   -- The centre of the player's triangle
   local pc = arena.get_centre(player.pos[1], player.pos[2], player.pos[3])

   -- Draw a circle where the player is
   gfx.setColor(0.6, 0.6, 0.6)
   gfx.circle("fill", pc[1], pc[2], arena.side/6)
   gfx.setColor(1, 1, 1)
   gfx.circle("line", pc[1], pc[2], arena.side/6)

   -- Draw a line from the circle to where the player is looking
   local looking_at =
      arena.get_vertex(player.pos[1], player.pos[2], player.pos[3], player.dir)
   gfx.line(pc[1], pc[2], looking_at[1], looking_at[2])

   -- Draw a white point where the player is looking
   gfx.circle("fill", looking_at[1], looking_at[2], arena.side / 20)
end

function draw.hazards(hazards)

   gfx.setColor(1, 0.5, 0)
   for _, s in pairs(hazards.spinners) do
      local c = arena.get_centre(s.pos[1], s.pos[2], s.pos[3])

      -- Draw a circle where the spinner is
      gfx.circle("fill", c[1], c[2], arena.side / 10)

      -- Draw a line from the circle to where the spinner is looking
      local looking_at = arena.get_vertex(s.pos[1], s.pos[2], s.pos[3], s.dir)
      local look_line = { c[1], c[2], looking_at[1], looking_at[2] }
      gfx.line(look_line)

      -- Draw a dot where the spinner is looking

      gfx.circle("fill", looking_at[1], looking_at[2], arena.side / 20)
   end

   gfx.setColor(0.7, 0.2, 0.5)
   for _, w in pairs(hazards.walkers) do
      local c = arena.get_centre(w.pos[1], w.pos[2], w.pos[3])
      gfx.circle("fill", c[1], c[2], arena.side / 10)

      local looking_at =
         arena.get_vertex(w.pos[1], w.pos[2], w.pos[3], w.avoid)
      local look_line = { c[1], c[2], looking_at[1], looking_at[2] }
      gfx.line(look_line)

      -- Draw a dot where the spinner is looking

      gfx.circle("fill", looking_at[1], looking_at[2], arena.side / 20)

   end
end

function draw.obstacles(obstacles)
   gfx.setColor(1, 1, 1)
   for _, triord in pairs(obstacles) do
      gfx.polygon("fill", arena.get_vertices(triord[1], triord[2], triord[3]))
   end
end

function draw.walls(wall_pairs)
   gfx.setColor(1, 1, 1)
   gfx.setLineWidth(5)
   for _, wall_pair in pairs(wall_pairs) do
      local line = arena.get_wall_line(wall_pair[1], wall_pair[2])
      gfx.line(line[1], line[2], line[3], line[4])
   end
   gfx.setLineWidth(1)
end

function draw.highlight_triangle(triord)
   gfx.setColor(0.4, 0.4, 0.4, 0.5)
   gfx.polygon("fill", arena.get_vertices(triord[1], triord[2], triord[3]))
end

function draw.arena()
   gfx.setColor(1, 1, 1)
   local triangles = arena.get_all_triangle_vertices()
   for _, vertices in pairs(triangles) do
      gfx.polygon("line", vertices)
   end
end

return draw