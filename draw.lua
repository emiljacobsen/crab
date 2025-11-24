local draw = {}

-- Imports

local geo = require "geometry"

-- I need the instance of arena set up in main.lua
local arena = nil
-- Same with entities
local ent = nil

-- Shorthand
local gfx = love.graphics

local font = gfx.newFont("fonts/gerhaus.ttf", 20)
gfx.setFont(font)

local ui = {
   panel = {}
}

local panel_ul
local panel_lr
local panel_offset = 30
local panel_next = 10

-- Needs arena_arg to be the instance of arena set up in main.lua.
-- The other two args describe the box bounding
-- the panel of UI elements on the right.
function draw.setup(arena_arg, panel_ul_arg, panel_lr_arg, entities)
   arena = arena_arg
   panel_ul = panel_ul_arg
   panel_lr = panel_lr_arg
   ent = entities
end

function draw.add_ui(zone, type, text, colour)
   local elt = {}

   elt.pos = {}
   elt.pos[1] = panel_ul[1]
   elt.pos[2] = panel_ul[2] + panel_next
   panel_next = panel_next + panel_offset

   elt.text = text
   elt.type = type
   elt.colour = colour

   local key = #(ui[zone]) + 1

   ui[zone][key] = elt

   return key
end

function draw.update_ui_text(zone, key, text)
   ui[zone][key].text = text
end

function draw.check_buttons(x, y)
   for key, elt in pairs(ui.panel) do
      if elt.type == "button" then
         if x >= elt.pos[1]
            and y >= elt.pos[2]
            and y <= elt.pos[2] + 23
         then
            return true, "panel", key
         end
      end
   end
   return false, nil
end

-- Draw a dot in the center of a triangle.
function draw.dot(triord, colour)
   if triord == nil then return end

   gfx.setColor(colour[1], colour[2], colour[3])
   local centre = arena.get_centre(triord[1], triord[2], triord[3])
   local dot_size = arena.diametre / 16
   gfx.circle("fill", centre[1], centre[2], dot_size)
end

-- Draw the player.
function draw.player()

   -- The centre of the player's triangle
   local pc = arena.get_centre(
      ent.player.pos[1],
      ent.player.pos[2],
      ent.player.pos[3])

   -- Draw a circle where the player is
   gfx.setColor(0.6, 0.6, 0.6)
   gfx.circle("fill", pc[1], pc[2], arena.side/6)
   gfx.setColor(1, 1, 1)
   gfx.circle("line", pc[1], pc[2], arena.side/6)

   -- Draw the player's health
   -- TODO: this newText is slow, but I don't know how else to get the width.
   local health_text = gfx.newText(font, ent.player.health)
   local health_w, health_h = health_text:getDimensions()
   -- gfx.draw(
   --    health_text,
   --    math.floor(pc[1]-health_w/2),
   --    math.floor(pc[2]-health_h/2))
   gfx.print(ent.player.health, 
      math.floor(pc[1]-health_w/2),
      math.floor(pc[2]-health_h/2))

   -- Draw a line from the circle to where the player is looking
   local looking_at = arena.get_vertex(
      ent.player.pos[1],
      ent.player.pos[2],
      ent.player.pos[3],
      ent.player.dir)
   local looking_vec
      = geo.line_to_vec(
         pc[1], pc[2],
         looking_at[1], looking_at[2])
   local looking_from
      = geo.translate(
         pc,
         geo.scale(looking_vec, arena.side/ 6 / geo.norm(looking_vec)))
   gfx.line(looking_from[1], looking_from[2], looking_at[1], looking_at[2])

   -- Draw a white point where the player is looking
   gfx.circle("fill", looking_at[1], looking_at[2], arena.side / 20)
end

function draw.goal(triord)
   gfx.setColor(1, 1, 0, 0.5)
   gfx.polygon("fill", arena.get_vertices(triord[1], triord[2], triord[3]))
end

-- Draw the hazards
function draw.hazards()

   -- Draw the spinners

   for type, hazards in pairs(ent.hazards) do
      for _, h in pairs(hazards) do
         if type == "spinners" then
            gfx.setColor(1, 0.5, 0)

            local c = arena.get_centre(h.pos[1], h.pos[2], h.pos[3])

            -- Draw a circle where the spinner is
            gfx.circle("fill", c[1], c[2], arena.side / 10)

            -- Draw a line from the circle to where the spinner is looking
            local looking_at = arena.get_vertex(h.pos[1], h.pos[2], h.pos[3], h.dir)
            local look_line = { c[1], c[2], looking_at[1], looking_at[2] }
            gfx.line(look_line)

            -- Draw a dot where the spinner is looking

            gfx.circle("fill", looking_at[1], looking_at[2], arena.side / 20)

            -- Draw a line towards the spinner's next position

            local looking_dir = (h.dir - h.sign) % 3
            looking_at = arena.get_mid(h.pos[1], h.pos[2], h.pos[3], looking_dir)
            look_line = { c[1], c[2], looking_at[1], looking_at[2] }
            gfx.line(look_line)
            gfx.circle("fill", looking_at[1], looking_at[2], arena.side / 20)

         -- Draw the walkers
         elseif type == "walkers" then
            gfx.setColor(0.7, 0.2, 0.5)

            -- The centre of the walker's triangle
            local c = arena.get_centre(h.pos[1], h.pos[2], h.pos[3])

            -- Draw the walker itself
            gfx.circle("fill", c[1], c[2], arena.side / 10)

            -- Indicate where the walker is "looking"
            -- First with a line:

            local move_dir = ent.hazard_going_towards(h, "walkers")
            local looking_at =
               arena.get_mid(h.pos[1], h.pos[2], h.pos[3], move_dir)
            local look_line = { c[1], c[2], looking_at[1], looking_at[2] }
            gfx.line(look_line)

            -- Then a dot where the walker is looking
            gfx.circle("fill", looking_at[1], looking_at[2], arena.side / 20)

            -- Indicate what the walker is avoiding.

            local dir1 = (h.avoid + 1) % 3
            local dir2 = (h.avoid - 1) % 3
            local vertex1 = arena.get_vertex(h.pos[1], h.pos[2], h.pos[3], dir1)
            local vertex2 = arena.get_vertex(h.pos[1], h.pos[2], h.pos[3], dir2)
            local vertex_avoid =
               arena.get_vertex(h.pos[1], h.pos[2], h.pos[3], h.avoid)

            -- Make this bigger for the avoid_line to lie closer to the grid line
            local close = 8
            local denom = close + 2

            local start = geo.scale(vertex1, close/denom)
            start = geo.translate(start, geo.scale(vertex2, 1/denom))
            start = geo.translate(start, geo.scale(vertex_avoid, 1/denom))

            local finish = geo.scale(vertex2, close/denom)
            finish = geo.translate(finish, geo.scale(vertex1, 1/denom))
            finish = geo.translate(finish, geo.scale(vertex_avoid, 1/denom))

            local avoid_line = { start[1], start[2], finish[1], finish[2] }
            gfx.setLineWidth(2)
            gfx.line(avoid_line)
            gfx.setLineWidth(1)
         end
      end
   end
end

-- Draw the obstacles.
-- `obstacles` is an array of triordinates { h, f, b }.
function draw.obstacles(obstacles)
   gfx.setColor(1, 1, 1)
   for _, triord in pairs(obstacles) do
      gfx.polygon("fill", arena.get_vertices(triord[1], triord[2], triord[3]))
   end
end

-- Draw the walls.
-- `wall_pairs` is an array of pairs { { h, f, b }, { h', f', b' } }.
function draw.walls(wall_pairs)
   gfx.setColor(1, 1, 1)
   gfx.setLineWidth(5)
   for _, wall_pair in pairs(wall_pairs) do
      local line = arena.get_wall_line(wall_pair[1], wall_pair[2])
      gfx.line(line[1], line[2], line[3], line[4])
   end
   gfx.setLineWidth(1)
end

-- Highlight the triangle at triordinate `triord` = { h, f, b }.
function draw.highlight_triangle(triord)
   gfx.setColor(0.4, 0.4, 0.4, 0.5)
   gfx.polygon("fill", arena.get_vertices(triord[1], triord[2], triord[3]))
end

-- Draw the arena.
function draw.arena()

   gfx.setColor(0.6, 0.6, 0.6)
   local triangles = arena.get_all_triangle_vertices()

   for _, vertices in pairs(triangles) do
      gfx.polygon("line", vertices)
   end

   local border_pairs = arena.get_borders()
   local cs = {
      { 1, 0, 0 },
      { 0, 1, 0 },
      { 0, 0, 1 }
   }
   for j = 1, 3 do
      gfx.setColor(cs[j][1], cs[j][2], cs[j][3])
      gfx.line(border_pairs[j][1])
      gfx.line(border_pairs[j][2])
   end
end

function draw.ui()

   for _, elt in pairs(ui.panel) do
      gfx.setColor(elt.colour[1], elt.colour[2], elt.colour[3])

      local x = elt.pos[1]
      local y = elt.pos[2]

      if elt.type == "text" then
         gfx.print({ {gfx.getColor()}, elt.text }, x, y)
      end

      if elt.type == "button" then
         gfx.print({ {gfx.getColor()}, elt.text }, x+3, y)
         gfx.rectangle("line",
            x,
            y,
            panel_lr[1]-panel_ul[1],
            font:getHeight() + 2)
      end

      y = y + panel_offset
   end

   function draw.dead()
      gfx.setColor(1, 1, 1)
      gfx.print("You are dead.", 10, 10)
   end

   function draw.victory()
      gfx.setColor(1, 1, 1)
      gfx.print("You are victorious!", 10, 10)
   end
end

return draw