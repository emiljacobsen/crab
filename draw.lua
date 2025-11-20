local draw = {}

local arena = {}

local gfx = love.graphics

function draw.setup(arena_arg)
   arena = arena_arg
end

function draw.player(player, left, right, behind)

   -- Draw red dots on player adjacent triangles

   local centre = {}

   gfx.setColor(1, 0, 0)
   if left ~= nil then
      centre = arena.get_centre(left[1], left[2], left[3])
      gfx.circle("fill", centre[1], centre[2], arena.diametre / 12)
   end

   gfx.setColor(0, 1, 0)
   if right ~= nil then
      centre = arena.get_centre(right[1], right[2], right[3])
      gfx.circle("fill", centre[1], centre[2], arena.diametre / 12)
   end

   gfx.setColor(1, 1, 0)
   if behind ~= nil then
      centre = arena.get_centre(behind[1], behind[2], behind[3])
      gfx.circle("fill", centre[1], centre[2], arena.diametre / 12)
   end

   -- The centre of the player's triangle
   local pc = arena.get_centre(player.pos[1], player.pos[2], player.pos[3])

   -- Draw a circle where the player is
   gfx.setColor(1, 1, 1)
   gfx.circle("line", pc[1], pc[2], arena.side/6)

   -- Draw a line from the circle to where the player is looking
   local looking_at =
      arena.get_vertex(player.pos[1], player.pos[2], player.pos[3], player.dir)
   gfx.line(pc[1], pc[2], looking_at[1], looking_at[2])

   -- Draw a white point where the player is looking
   gfx.circle("fill", looking_at[1], looking_at[2], arena.side / 20)
end

function draw.spinners(spinners)
   gfx.setColor(1, 0, 0)

   for _, s in ipairs(spinners) do
      local sc = arena.get_centre(s.pos[1], s.pos[2], s.pos[3])

      -- Draw a circle where the spinner is
      gfx.circle("fill", sc[1], sc[2], arena.side/10)

      -- Draw a line from the circle to where the spinner is looking
      local looking_at = arena.get_vertex(s.pos[1], s.pos[2], s.pos[3], s.dir)
      local look_line = { sc[1], sc[2], looking_at[1], looking_at[2] }
      gfx.line(look_line)

      -- Draw a dot where the spinner is looking

      gfx.circle("fill", looking_at[1], looking_at[2], arena.side / 20)
   end
end

function draw.obstacles(obstacles)
   gfx.setColor(1, 1, 1)
   for _, triord in ipairs(obstacles) do
      gfx.polygon("fill", arena.get_vertices(triord[1], triord[2], triord[3]))
   end
end

function draw.walls(wall_pairs)
   gfx.setColor(1, 1, 1)
   gfx.setLineWidth(5)
   for _, wall_pair in ipairs(wall_pairs) do
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
   for _, vertices in ipairs(triangles) do
      gfx.polygon("line", vertices)
   end
end

return draw