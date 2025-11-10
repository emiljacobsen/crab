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

-- TODO: separate into a "triangular grid" library
--       and an arena library

-- Imports

local geo = require "geometry"

-- Variable scoped to the file

local sqrt3 = math.sqrt(3)
local first_triangle = {}
local first_centre = {}
local offset_h = {}
local offset_f = {}
local offset_b = {}
local h_lo
local h_hi
local f_lo
local f_hi
local b_lo
local b_hi

-- The exported module
local arena = {}

-- The possible directions of a triangle,
-- matched with the parity of `h+f+b`.
-- TODO: consdier reformatting to arena.up, arena.down.
arena.dirs = {
   up = 1,
   down = 0
}

-- Set up the basic parameters of the arena.
-- Must be run before anyting else.
function arena.setup(scale, ul, lr)
   -- The number of triangles sharing a side with a side of the hexagon.
   arena.scale = scale
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

   -- The first upright triangle on the first row of the hexagon.
   -- With tri-ordinate (1, 1, 1).
   -- TODO: shift down a bit, to center the hexagon vertically
   first_triangle = {
      arena.side * arena.scale / 2, 0 ,
      arena.side * (arena.scale-1) / 2, arena.diametre,
      arena.side * (arena.scale+1) / 2, arena.diametre
   }
   first_triangle = geo.translate(first_triangle, ul)

   -- The centre of first_triangle
   first_centre = geo.centre(first_triangle)

   -- Tri-ordinate bounds:
   h_lo = 1
   h_hi = 2 * arena.scale
   f_lo = -2 * arena.scale + 2
   f_hi = 1
   b_lo = -arena.scale + 2
   b_hi = arena.scale + 1
end

-- Get the direction of a triangle
-- (equal to either of `arena.dirs.up` or `arena.dirs.down`).
function arena.get_dir(h, f, b)
   return (h + f + b) % 2
end

function arena.get_b(h, f, dir)
    if dir == arena.dirs.up then
      return 3 - h - f
   else
      return 4 - h - f
   end
end

-- Check if a tri-ordinate `{ h, f, b }` is valid.
-- A triangle is uniquely determined by `(h, f, h+f+b % 2)`.
-- The determination works as follows:
-- - if dir is up, `b = h + f - 1`
-- - if dir is down, `b = h + fs`.
-- TODO: consider not exporting this.
function arena.check_valid(h, f, b)
   return b == arena.get_b(h, f, arena.get_dir(h, f, b))
end

-- Get the coordinates at the centre of the triangle at (h, f, b)
function arena.get_centre(h, f, b)
   local centre = geo.translate(first_centre, geo.scale(offset_h, h-1))
   centre = geo.translate(centre, geo.scale(offset_f, f-1))
   centre = geo.translate(centre, geo.scale(offset_b, b-1))
   return centre
end

-- Get the coordinates at the vertices of the triangle at (h, f, b)
-- Returns an array { x1, y1, x2, y2, x3, y3 }
function arena.get_vertices(h, f, b)
   -- Get the centre first:
   local centre = arena.get_centre(h, f, b)

   -- Then get the vertices:
   local x1, y1, x2, y2, x3, y3

   if arena.get_dir(h, f, b) == arena.dirs.up then
      x1 = centre[1]
      y1 = centre[2] - arena.side / sqrt3

      x2 = centre[1] - arena.side / 2
      y2 = centre[2] + arena.side / 2 / sqrt3

      x3 = centre[1] + arena.side / 2
      y3 = centre[2] + arena.side / 2 / sqrt3
   else
      x1 = centre[1]
      y1 = centre[2] + arena.side / sqrt3

      x2 = centre[1] - arena.side / 2
      y2 = centre[2] - arena.side / 2 / sqrt3

      x3 = centre[1] + arena.side / 2
      y3 = centre[2] - arena.side / 2 / sqrt3
   end

   return { x1, y1, x2, y2, x3, y3 }
end

-- Get the vertex opposite the h line
function arena.get_h_vertex(h, f, b)
   local centre = arena.get_centre(h, f, b)
   local x, y

   if arena.get_dir(h, f, b) == arena.dirs.up then
      x = centre[1]
      y = centre[2] - arena.side / sqrt3
   else
      x = centre[1]
      y = centre[2] + arena.side / sqrt3
   end
   return { x, y }
end

-- Get the vertex opposite the f line
function arena.get_f_vertex(h, f, b)
   local centre = arena.get_centre(h, f, b)
   local x, y

   if arena.get_dir(h, f, b) == arena.dirs.up then
      x = centre[1] + arena.side / 2
      y = centre[2] + arena.side / 2 / sqrt3
   else
      x = centre[1] - arena.side / 2
      y = centre[2] - arena.side / 2 / sqrt3
   end
   return { x, y }
end

-- Get the vertex opposite the b line
function arena.get_b_vertex(h, f, b)
   local centre = arena.get_centre(h, f, b)
   local x, y

   if arena.get_dir(h, f, b) == arena.dirs.up then
      x = centre[1] - arena.side / 2
      y = centre[2] + arena.side / 2 / sqrt3
   else
      x = centre[1] + arena.side / 2
      y = centre[2] - arena.side / 2 / sqrt3
   end
   return { x, y }
end

-- Uses the wrapping/warping logic to shift a tri-ordinate into the arena.
-- Returns an array { h', f', b' }.
-- Assumes (for now) at most one tri-ordinate is OOB, and by at most 1.
local function wrap(h, f, b)
   if h == h_lo - 1 then
      return { h_hi, f - arena.scale, b - arena.scale }
   elseif h == h_hi + 1 then
      return { h_lo, f + arena.scale, b + arena.scale }
   elseif f == f_lo - 1 then
      return { h - arena.scale, f_hi, b - arena.scale }
   elseif f == f_hi + 1 then
      return { h + arena.scale, f_lo, b + arena.scale }
   elseif b == b_lo - 1 then
      return { h - arena.scale, f - arena.scale, b_hi }
   elseif b == b_hi + 1 then
      return { h + arena.scale, f + arena.scale, b_lo }
   else
      return { h, f, b }
   end
end

-- Get the adjacent tri-ordinates (including adjacent by warping)
-- Returns an array of arrays
-- { {h1, f1, b1}, ... }
function arena.get_adjacents(h, f, b)
   local adjacents = {
      arena.get_h_adjacent(h, f, b),
      arena.get_f_adjacent(h, f, b),
      arena.get_b_adjacent(h, f, b)
   }
   return adjacents
end

function arena.get_h_adjacent(h, f, b)
   -- +1 if dir == 1, and -1 if dir == 0
   local sign = (-1)^(arena.get_dir(h, f, b)+1)
   return wrap(h+sign, f, b)
end

function arena.get_f_adjacent(h, f, b)
   -- +1 if dir == 1, and -1 if dir == 0
   local sign = (-1)^(arena.get_dir(h, f, b)+1)
   return wrap(h, f+sign, b)
end

function arena.get_b_adjacent(h, f, b)
   -- +1 if dir == 1, and -1 if dir == 0
   local sign = (-1)^(arena.get_dir(h, f, b)+1)
   return wrap(h, f, b+sign)
end

function arena.get_adjacent(h, f, b, dir)
   if dir == 0 then
      return arena.get_h_adjacent(h, f, b)
   elseif dir == 1 then
      return arena.get_f_adjacent(h, f, b)
   elseif dir == 2 then
      return arena.get_b_adjacent(h, f, b)
   end
end

-- Get all vertices of all triangles
-- Returns an array of arrays
-- { { x1, y1, x2, y2, x3, y3 }, ... }
function arena.get_all_triangles()

   -- TODO: do sanity check that all triords are valid

   local triangles = {}

   -- Upper half of the hexagon

   local f_bnd = f_lo + arena.scale
   for h = 1, arena.scale do
      for f = f_bnd, f_hi do
         triangles[#triangles+1] =
            arena.get_vertices(h, f, arena.get_b(h, f, arena.dirs.up))
         triangles[#triangles+1] =
            arena.get_vertices(h, f, arena.get_b(h, f, arena.dirs.down))
      end
      f_bnd = f_bnd - 1
      triangles[#triangles+1] =
         arena.get_vertices(h, f_bnd, arena.get_b(h, f_bnd, arena.dirs.up))
   end

   -- Sanity check
   -- print("upper half f_bnd check in arena.get_all_triangles:", f_bnd == f_lo)

   -- Lower half of the hexagon

   f_bnd = f_hi
   for h = arena.scale+1, 2 * arena.scale do
      triangles[#triangles+1] =
         arena.get_vertices(h, f_bnd, arena.get_b(h, f_bnd, arena.dirs.down))
      f_bnd = f_bnd - 1

      for f = f_lo, f_bnd do
         triangles[#triangles+1] =
            arena.get_vertices(h, f, arena.get_b(h, f, arena.dirs.up))
         triangles[#triangles+1] =
            arena.get_vertices(h, f, arena.get_b(h, f, arena.dirs.down))
      end
   end

   -- Sanity check
   -- print(
   --    "lower half f_bnd check in arena.get_all_triangles:",
   --    f_bnd == f_lo + arena.scale - 1
   -- )

   return triangles
end

-- Returns the line between the (adjacent) triangles at
-- triordinates triord1 and triord2.
-- The triords are arrays { h, f, b }.
-- Returns an array { x1, y1, x2, y2 }
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

-- TODO: get lines

return arena