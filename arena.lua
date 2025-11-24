local arena = {}

-- Explainer:

-- The grid is cut out by parallel lines in three directions:
-- - horizontal,
-- - "forward slash"
-- - "back slash"

-- Each triangle thus has coordinates `(h, fs, bs)`, and
-- - each time you cross a horizontal line (going down),
--   `h` is incremented
-- - each time you cross a "forward slash" line (going left+up),
--   `fs` is incremented,
-- - each time you cross a "back slash" line (going right+up),
--   `bs` is incremented.
-- (This convention makes adjacencies tidy but signs weird.)

-- The grid is hexagonal in shape.
-- A side of the hexagon contains the sides of `scale` triangles.
-- That means each type of line intersects the hexagon `2*scale` times.

-- The first triangle on the first row of the hexagon has coordinates (1,1,1),
-- and this triangle points upwards.
-- It will follow that:
-- - `h+fs+bs` is odd for upwards triangles,
-- - `h+fs+bs` is even for downwards triangles.

-- These three coordinates overdetermine the grid position:
-- a triangle is uniquely determined by `(h, fs, h+fs+bs % 2)`.
-- More precise coordinates might therefore be given as
-- `(h, fs, dir)`, where `dir` is a bit recording if the triangle
-- points up or down.
-- The determination works as follows:
-- - if `dir` is up, `bs = h + fs - 1`
-- - if `dir` is down, `bs = h + fs`.

-- Standard adjacencies:
-- A generic upward triangle `(h, fs, bs)` has adjacent triangles
-- `(h+1, fs, bs)`, `(h, fs+1, bs)`, `(h, fs, bs+1)`.
-- A generic downward triangle `(h, fs, bs)` has adjacent triangles
-- `(h-1, fs, bs)`, `(h, fs-1, bs)`, `(h, fs, bs-1)`.

-- Warping/wrapping:
-- Bounds:
-- - `h` runs between `1` and `2*scale`
-- - `fs` runs between `-2*scale + 2` and `1`
-- - `bs` runs between `-scale + 2` and `scale + 1`
-- h warp:
-- - `(0, fs, bs) = (2*scale, fs - scale, bs - scale)`
-- - `(2*scale+1, fs, bs) = (1, fs + scale, bs + scale)`
-- fs warp:
-- - `(h, -2*scale + 1, bs) = (h + scale, 1, bs - scale)`
-- - `(h, 2, bs) = (h - scale, -2*scale + 2, bs + scale)`
-- bs warp:
-- - `(h, fs, -scale + 1) = (h + scale, fs - scale, scale + 1)`
-- - `(h, fs, scale + 2) = (h - scale, fs + scale, -scale + 2)`

-- Call the triple `(h, fs, bs)` the "tri-ordinate" of the respective triangle.

-- Going from "tri-ordinates" to co-ordinates
-- Set a bounding box spanned by two points `ul`, `lr`.
-- Assume the box is square, with side `width`.
-- That gives a triangle side of `width / (2 * scale)`
-- (from the equator of the hexagon).
-- Call the triangle side `side`
-- and the triangle height `diametre`.
-- The vertices of the (upright) triangle at tri-ordinate `(1,1,1)`
-- have co-ordinates offset from `ul` by:
-- - `{ side * scale / 2, 0 }` (upper vertex)
-- - `{ side * (scale - 1) / 2, diametre }` (lower left vertex)
-- - `{ side * (scale + 1) / 2, diametre }` (lower right vertex)
-- This gives the centre od that triangle.
-- You get the centre of the triangle at `(h, fs, bs)` by offsetting with
-- - `offset_h` `h-1` times,
-- - `offset_fs` `fs-1` times, and
-- - `offset_bs` `bs-1` times;
-- where
-- - `offset_h = { 0, 2 * diametre / 3 }
-- - `offset_fs = { -side / 2, -diametre / 3 }
-- - `offset_bs = { side / 2, diametre / 3 }.
-- Knowing the centre of a triangle,
-- you get the vertices by offsetting with
-- - `{ 0, -side / sqrt3 }`,
-- - `{ -side / 2, side / 2 / sqrt3 }`, or
-- - `{ side / 2, side / 2 / sqrt3 }`,
-- when `dir` is up, and
-- - `{ 0, side / sqrt3 }`,
-- - `{ -side / 2, -side / 2 / sqrt3 }`, or
-- - `{ side / 2, -side / 2 / sqrt3 }`,
-- when `dir` is down.

-- Going from co-ordinates to "tri-ordinates"
-- Get h:
-- Compute 1 + floor of (y - arena_y_min) / (2 * scale * diametre)
-- Get f:
-- It's like with h except the y-axis is exhanged for the (-x-y)-axis.
-- Compute 1 + floor of (proj(axis) - arena_axis_min) / (2 * scale * diametre)
-- Get b:
-- It's like with h except the y-axis is exhanged for the (x-y)-axis.
-- Compute 1 + floor of (proj(axis) - arena_axis_min) / (2 * scale * diametre)
-- So I need to be able to project onto these axes,
-- and compute the relevant arena_axis_mins
-- (they should follow from the work needed to change to line rendering).

-- Imports

local geo = require "geometry"
local util = require "utility"

-- Need this to be the same instance as in main.lua
local grid = nil

-- Variable scoped to the file

local sqrt3 = math.sqrt(3)

-- The first upright triangle on the first row of the hexagon.
-- With tri-ordinate (1, 1, 1).
-- This variable stores its screen coordinates.
local first_triangle = nil
local first_centre = nil

-- TODO: give offset_vectors explainer comments (move down from top explainer)

local offset_h = nil
local offset_f = nil
local offset_b = nil

-- Set up the basic parameters of the arena.
-- Must be run before anyting else.
-- The arena fills out the bounding box with
-- upper left corner `ul`, and
-- lower right corner `lr`.
function arena.setup(grid_arg, ul, lr)
   grid = grid_arg

   -- The number of triangles sharing a side with a side of the hexagon.
   arena.scale = grid.scale
   -- The upper left bound of the arena square
   arena.ul = ul
   -- The lower right bound of the arena square
   arena.lr = lr
   -- The width of the arena square
   -- TODO: consider scoping to file
   arena.width = math.min(
      math.abs(lr[1] - ul[1]),
      math.abs(lr[2] - ul[2])
   )
   -- The side length of the (equilateral) triangles
   arena.side = arena.width / 2 / arena.scale
   -- The diametre/height of the triangles
   -- TODO: consider scoping to file
   arena.diametre = sqrt3 * arena.side / 2

   -- Offset vectors, needed to figure out coordinates.

   offset_h = { 0, 2 * arena.diametre / 3 }
   offset_f = { -arena.side / 2, -arena.diametre / 3 }
   offset_b = { arena.side / 2, -arena.diametre / 3 }

   -- TODO: shift down a bit, to center the hexagon vertically
   --       (Should replace ARENA_Y_OFFSET.)
   first_triangle = {
      arena.side * arena.scale / 2, 0 ,
      arena.side * (arena.scale-1) / 2, arena.diametre,
      arena.side * (arena.scale+1) / 2, arena.diametre
   }
   first_triangle = geo.translate(first_triangle, ul)
   first_centre = geo.centre(first_triangle)
end

-- Get the coordinates at the centre of the triangle at (h, f, b).
-- Returns { x, y }.
function arena.get_centre(h, f, b)
   local centre = geo.translate(first_centre, geo.scale(offset_h, h-1))
   centre = geo.translate(centre, geo.scale(offset_f, f-1))
   centre = geo.translate(centre, geo.scale(offset_b, b-1))
   return centre
end

-- Get the coordinates at the vertices of the triangle at (h, f, b).
-- Returns an array { x1, y1, x2, y2, x3, y3 }.
function arena.get_vertices(h, f, b)
   local h_v = arena.get_h_vertex(h, f, b)
   local f_v = arena.get_f_vertex(h, f, b)
   local b_v = arena.get_b_vertex(h, f, b)

   return { h_v[1], h_v[2], f_v[1], f_v[2], b_v[1], b_v[2] }
end

-- Get the vertex opposite the h line.
-- Returns { x, y }.
function arena.get_h_vertex(h, f, b)
   local centre = arena.get_centre(h, f, b)
   local x = centre[1]
   local y = centre[2] + grid.get_sign(h, f, b) * arena.side / sqrt3
   return { x, y }
end

-- Get the vertex opposite the f line.
-- Returns { x, y }.
function arena.get_f_vertex(h, f, b)
   local centre = arena.get_centre(h, f, b)
   local sign = grid.get_sign(h, f, b)
   local x = centre[1] - sign * arena.side / 2
   local y = centre[2] - sign * arena.side / 2 / sqrt3
   return { x, y }
end

-- Get the vertex opposite the b line.
-- Returns { x, y }.
function arena.get_b_vertex(h, f, b)
   local centre = arena.get_centre(h, f, b)
   local sign = grid.get_sign(h, f, b)
   local x = centre[1] + sign * arena.side / 2
   local y = centre[2] - sign * arena.side / 2 / sqrt3
   return { x, y }
end

-- Get the vertex in the `dir` direction / opposite the `dir` line.
-- Returns { x, y }
function arena.get_vertex(h, f, b, dir)
   if dir == grid.dirs.h then
      return arena.get_h_vertex(h, f, b)
   elseif dir == grid.dirs.f then
      return arena.get_f_vertex(h, f, b)
   elseif dir == grid.dirs.b then
      return arena.get_b_vertex(h, f, b)
   end
end

-- Get the mid point of the h line.
-- Returns { x, y }.
function arena.get_h_mid(h, f, b)
   local centre = arena.get_centre(h, f, b)
   local vertex = arena.get_h_vertex(h, f, b)
   local mid = geo.scale(geo.translate(centre, geo.scale(vertex, -1/3)), 3/2)
   return { mid[1], mid[2] }
end

-- Get the mid point of the f line.
-- Returns { x, y }.
function arena.get_f_mid(h, f, b)
   local centre = arena.get_centre(h, f, b)
   local vertex = arena.get_f_vertex(h, f, b)
   local mid = geo.scale(geo.translate(centre, geo.scale(vertex, -1/3)), 3/2)
   return { mid[1], mid[2] }
end

-- Get the mid point of the b line.
-- Returns { x, y }.
function arena.get_b_mid(h, f, b)
   local centre = arena.get_centre(h, f, b)
   local vertex = arena.get_b_vertex(h, f, b)
   local mid = geo.scale(geo.translate(centre, geo.scale(vertex, -1/3)), 3/2)
   return { mid[1], mid[2] }
end

-- Get the mid point of the `dir` line.
-- Returns { x, y }
function arena.get_mid(h, f, b, dir)
   if dir == grid.dirs.h then
      return arena.get_h_mid(h, f, b)
   elseif dir == grid.dirs.f then
      return arena.get_f_mid(h, f, b)
   elseif dir == grid.dirs.b then
      return arena.get_b_mid(h, f, b)
   end
end

-- Get all vertices of all triangles
-- Returns an array of arrays
-- { { x1, y1, x2, y2, x3, y3 }, ... }
function arena.get_all_triangle_vertices()

   -- TODO: do sanity check that all triords are valid

   local triangles = {}

   for i, triord in ipairs(grid.get_all_triangles()) do
      triangles[i] = arena.get_vertices(triord[1], triord[2], triord[3])
   end

   return triangles
end

-- Returns the line between the (adjacent) triangles at
-- triordinates triord1 and triord2.
-- The triords are arrays { h, f, b }.
-- Returns an array { x1, y1, x2, y2 }.
function arena.get_wall_line(triord1, triord2)
   local start = {}
   local finish = {}

   -- TODO: make a safety check that they are actually adjacent.

   if triord1[1] ~= triord2[1] then
      start = arena.get_f_vertex(triord1[1], triord1[2], triord1[3])
      finish = arena.get_b_vertex(triord1[1], triord1[2], triord1[3])
   elseif triord1[2] ~= triord2[2] then
      start = arena.get_h_vertex(triord1[1], triord1[2], triord1[3])
      finish = arena.get_b_vertex(triord1[1], triord1[2], triord1[3])
   elseif triord1[3] ~= triord2[3] then
      start = arena.get_h_vertex(triord1[1], triord1[2], triord1[3])
      finish = arena.get_f_vertex(triord1[1], triord1[2], triord1[3])
   end

   return { start[1], start[2], finish[1], finish[2] }
end

-- Returns the triordinate of the triangle
-- containing the point (x, y).
-- Returns a triordinate array { h, f, b }.
function arena.coord_to_triord(x, y)
   local h = 1 +
      math.floor((y - ARENA_Y_OFFSET) / arena.diametre)

   local f_offset_vertex = arena.get_h_vertex(1, 1, 1)
   local f_offset = -f_offset_vertex[1]
      - (f_offset_vertex[2] - ARENA_Y_OFFSET) / sqrt3
   local f = 2 +
      math.floor((-x - (y - ARENA_Y_OFFSET) / sqrt3 - f_offset) / arena.side)

   local b_offset_vertex =
      arena.get_h_vertex(1, 1 - arena.scale, 1 + arena.scale)
   local b_offset =
      b_offset_vertex[1] - (b_offset_vertex[2] - ARENA_Y_OFFSET) / sqrt3
   local b = 5 +
      math.floor((x - (y - ARENA_Y_OFFSET) / sqrt3 - b_offset) / arena.side)

   return util.string_to_triord(h .. "," .. f .. "," .. b)
end

-- TODO: get lines

-- Returns an array
-- { { { x1, y1, x2, y2 }, {x1', y1', x2', y2'} }, ... }
function arena.get_borders()
   local line_pairs = {}
   local border_pairs = grid.get_borders()
   local pt1, pt2
   local line_pair = {}
   local t

   for key, border_pair in pairs(border_pairs) do
      line_pair = {}

      t = border_pair[2][1][1]
      pt1 = arena.get_vertex(t[1], t[2], t[3], border_pair[1])
      t = border_pair[2][1][2]
      pt2 = arena.get_vertex(t[1], t[2], t[3], border_pair[1])
      line_pair[1] = { pt1[1], pt1[2], pt2[1], pt2[2] }

      t = border_pair[2][2][1]
      pt1 = arena.get_vertex(t[1], t[2], t[3], border_pair[1])
      t = border_pair[2][2][2]
      pt2 = arena.get_vertex(t[1], t[2], t[3], border_pair[1])
      line_pair[2] = { pt1[1], pt1[2], pt2[1], pt2[2] }

      line_pairs[key] = line_pair
   end

   return line_pairs
end

return arena